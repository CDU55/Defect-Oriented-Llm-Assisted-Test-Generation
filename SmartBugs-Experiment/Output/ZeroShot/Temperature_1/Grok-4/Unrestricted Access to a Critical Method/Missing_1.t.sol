
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_1} from "../src/Missing_1.sol";

contract TestAccessControlMissing_1 is Test {
    Missing_1 missing;
    address initialOwner;

    function setUp() public {
        initialOwner = makeAddr("initialOwner");
        vm.prank(initialOwner);
        missing = new Missing_1();
        vm.prank(initialOwner);
        missing.IamMissing();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != initialOwner);

        // --- 2. State Configuration ---
        

        // --- 3. Execution & Assertion ---
        
        vm.prank(caller);
        missing.IamMissing();
        bytes32 ownerSlot = bytes32(uint256(0));
        address newOwner = address(uint160(uint256(vm.load(address(missing), ownerSlot))));
        assertEq(newOwner, caller);
    }
}
