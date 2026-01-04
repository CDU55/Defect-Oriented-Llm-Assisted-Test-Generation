
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Reentrance.sol";

contract TestReentrancyReentrance is Test {
    Reentrance public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrance();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_reentrancyExploit(uint256 attackVal) public {
        vm.assume(attackVal > 0.1 ether && attackVal < 100 ether);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy vulnerability not detected: State updated before external call.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrance public _victim;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = Reentrance(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        _victim.donate{value: val}(address(this));
    }

    function attack(uint256 val) public {
        storedAttackVal = val;
        _victim.withdraw(val);
    }

    receive() external payable {
        if (_victim.balanceOf(address(this)) >= storedAttackVal) {
            exploitSucceeded = true;
        }
    }
}
