
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Rubixi} from "../src/Rubixi.sol";

contract TestAccessControlRubixi is Test {
    Rubixi rubixi;

    function setUp() public {
        rubixi = new Rubixi();
        // ensure creator is NOT this test contract by having someone else call DynamicPyramid
        address initialCreator = address(0xBEEF);
        vm.prank(initialCreator);
        rubixi.DynamicPyramid();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != address(0xBEEF));

        vm.prank(caller);
        rubixi.DynamicPyramid();
    }
}
