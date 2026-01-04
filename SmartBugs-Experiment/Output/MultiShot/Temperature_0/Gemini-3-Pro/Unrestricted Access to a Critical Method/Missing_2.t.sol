
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_2} from "../src/Missing_2.sol";

contract TestAccessControlMissing_2 is Test {
    Missing_2 public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Missing_2();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // --- 2. State Configuration ---
        
        // --- 3. Execution & Assertion ---
        
        vm.prank(caller);

        _contractUnderTest.missing();

        // Verify side effect: caller is now the owner.
        // Since 'owner' is private and at slot 0, we load it directly to verify the change.
        bytes32 ownerSlot = vm.load(address(_contractUnderTest), bytes32(uint256(0)));
        address newOwner = address(uint160(uint256(ownerSlot)));
        
        assertEq(newOwner, caller);
    }
}
