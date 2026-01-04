
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_2} from "../src/Missing_2.sol";

contract TestAccessControlMissing_2 is Test {
    Missing_2 internal _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Missing_2();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        // 1. Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // 2. Exclude the Zero Address
        vm.assume(caller != address(0));

        // 3. Exclude Foundry Internals (Dynamic)
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // 2. Exclude ALL privileged roles.
        // The owner is stored in slot 0 and defaults to address(0).
        // Since we exclude address(0) above, we are not testing with the current owner.

        // --- 2. State Configuration ---
        
        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        _contractUnderTest.missing();
        
        // ASSERT SUCCESS
        // Check that the caller successfully became the owner.
        // 'owner' is a private variable at slot 0.
        bytes32 ownerSlot = vm.load(address(_contractUnderTest), bytes32(uint256(0)));
        address newOwner = address(uint160(uint256(ownerSlot)));
        
        assertEq(newOwner, caller, "Arbitrary caller should be able to become owner via missing()");
    }
}
