
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_1} from "../src/Missing_1.sol";

contract TestAccessControlMissing_1 is Test {
    Missing_1 private missingContract;

    function setUp() public {
        missingContract = new Missing_1();
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
        missingContract.IamMissing();
        
        // Verify side effects: caller should now be the owner.
        // owner is private and located at slot 0.
        bytes32 ownerSlot = vm.load(address(missingContract), bytes32(uint256(0)));
        address owner = address(uint160(uint256(ownerSlot)));
        
        assertEq(owner, caller, "Arbitrary caller should have successfully taken ownership");
    }
}
