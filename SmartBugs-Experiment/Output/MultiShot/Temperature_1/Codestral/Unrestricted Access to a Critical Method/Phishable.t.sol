
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract TestAccessControlPhishable is Test {
    Phishable public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Phishable(address(this));
    }

    function test_highlightArbitraryUserCanAccess(address caller, address payable recipient) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != _contractUnderTest.owner());

        vm.deal(address(_contractUnderTest), 1 ether);

        vm.prank(caller);
        _contractUnderTest.withdrawAll(recipient);

        vm.assertEq(address(_contractUnderTest).balance, 0);
    }
}
