
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract TestAccessControlPhishable is Test {
    Phishable public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Phishable(address(0xBEEF));
        vm.deal(address(_contractUnderTest), 10 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller, address payable recipient) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        vm.assume(caller != _contractUnderTest.owner());

        vm.assume(recipient != address(0));

        vm.deal(caller, 1 ether);

        uint256 balanceBefore = address(_contractUnderTest).balance;

        vm.prank(caller);
        _contractUnderTest.withdrawAll(recipient);

        assertEq(address(_contractUnderTest).balance, 0);
        assertEq(recipient.balance, balanceBefore);
    }
}
