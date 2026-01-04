
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SimpleSuicide} from "../src/SimpleSuicide.sol";

contract TestAccessControlSimpleSuicide is Test {
    SimpleSuicide public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new SimpleSuicide();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // No privileged roles exist in this contract, so no additional exclusions.

        // --- 2. State Configuration ---
        // Fund the contract so selfdestruct has an observable effect
        vm.deal(address(_contractUnderTest), 1 ether);
        uint256 callerBalanceBefore = caller.balance;

        // --- 3. Execution & Assertion ---
        vm.prank(caller);
        _contractUnderTest.sudicideAnyone();

        // Assert that the arbitrary caller received the contract balance via selfdestruct
        assertEq(caller.balance, callerBalanceBefore + 1 ether);
    }
}
