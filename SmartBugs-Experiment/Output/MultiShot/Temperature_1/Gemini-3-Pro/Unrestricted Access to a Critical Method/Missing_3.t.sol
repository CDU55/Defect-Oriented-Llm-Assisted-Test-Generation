
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_3} from "../src/Missing_3.sol";

contract TestAccessControlMissing_3 is Test {
    Missing_3 public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Missing_3();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // --- 2. Execution & Assertion ---
        
        vm.prank(caller);

        _contractUnderTest.Constructor();

        // Verify side effects: Caller should now be the owner (stored in slot 0)
        bytes32 ownerSlot = vm.load(address(_contractUnderTest), bytes32(uint256(0)));
        address newOwner = address(uint160(uint256(ownerSlot)));
        assertEq(newOwner, caller);
    }
}
