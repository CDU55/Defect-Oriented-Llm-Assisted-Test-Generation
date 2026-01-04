
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_2} from "../src/Missing_2.sol";

contract TestAccessControlMissing_2 is Test {
    Missing_2 public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Missing_2();
        address initialOwner = makeAddr("initial");
        vm.prank(initialOwner);
        _contractUnderTest.missing();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        address initialOwner = makeAddr("initial");
        vm.assume(caller != initialOwner);

        vm.prank(caller);
        _contractUnderTest.missing();

        assertEq(
            uint256(vm.load(address(_contractUnderTest), bytes32(0))),
            uint160(caller)
        );
    }
}
