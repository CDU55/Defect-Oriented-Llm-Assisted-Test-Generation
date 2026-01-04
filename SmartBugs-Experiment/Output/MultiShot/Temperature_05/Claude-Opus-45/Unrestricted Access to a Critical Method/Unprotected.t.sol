
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Unprotected} from "../src/Unprotected.sol";

contract TestAccessControlUnprotected is Test {
    Unprotected public _contractUnderTest;
    address public originalOwner;

    function setUp() public {
        originalOwner = address(this);
        _contractUnderTest = new Unprotected();
    }

    function test_highlightArbitraryUserCanAccess(address caller, address newOwner) public {
        // --- 1. Constraints ---
        // Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // Exclude the Zero Address
        vm.assume(caller != address(0));

        // Exclude Foundry Internals
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the original owner (the deployer/test contract)
        // This proves that an *arbitrary* non-owner user CAN access the function
        vm.assume(caller != originalOwner);

        // Constrain newOwner to be a valid address for the ownership change
        vm.assume(newOwner != address(0));

        // --- 2. State Configuration ---
        // No special funding or state setup required for this function

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller (who is NOT the owner)
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        // An arbitrary user who is NOT the owner can call changeOwner
        // If the contract is VULNERABLE (Unprotected), this call will SUCCEED
        // If the contract is SECURE (Protected with onlyowner), this call would REVERT
        _contractUnderTest.changeOwner(newOwner);

        // ASSERT SUCCESS - Verify the ownership was actually changed
        // We read the owner from storage slot 0 since it's a private variable
        bytes32 ownerSlot = vm.load(address(_contractUnderTest), bytes32(uint256(0)));
        address currentOwner = address(uint160(uint256(ownerSlot)));
        
        assertEq(currentOwner, newOwner, "Owner should have been changed by arbitrary caller");
        assertTrue(currentOwner != originalOwner || newOwner == originalOwner, "Ownership change should have occurred");
    }
}
