
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/src/Test.sol";
import {Rubixi} from "../src/Rubixi.sol";

contract TestAccessControlRubixi is Test {
    Rubixi public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Rubixi();
        _contractUnderTest.DynamicPyramid();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        address initialOwner = address(this);
        vm.assume(caller != initialOwner);

        vm.prank(caller);
        _contractUnderTest.DynamicPyramid();

        bytes32 creatorSlot = bytes32(uint(5));
        address newCreator = address(uint160(uint(vm.load(address(_contractUnderTest), creatorSlot))));
        assertEq(newCreator, caller);
    }
}
