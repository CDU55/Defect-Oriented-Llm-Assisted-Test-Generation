
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
        // Caller cannot be the test contract itself (the original owner)
        vm.assume(caller != address(this));
        // Exclude the Zero Address
        vm.assume(caller != address(0));
        // Exclude Foundry Internals
        vm.assume(caller != address(vm));
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the original owner (the deployer/test contract)
        vm.assume(caller != originalOwner);
        
        // Ensure newOwner is not zero address for meaningful test
        vm.assume(newOwner != address(0));

        // --- 2. State Configuration ---
        // No special state configuration needed for this test

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        // An arbitrary user should NOT be able to change the owner
        // If the contract is VULNERABLE (Unprotected), this call will SUCCEED, and the test will PASS.
        // If the contract is SECURE (Protected), this call will REVERT, and the test will FAIL.
        _contractUnderTest.changeOwner(newOwner);

        // ASSERT SUCCESS - Verify the owner was actually changed
        // We need to read the private owner variable using vm.load
        // owner is at storage slot 0
        bytes32 ownerSlot = vm.load(address(_contractUnderTest), bytes32(uint256(0)));
        address currentOwner = address(uint160(uint256(ownerSlot)));
        
        assertEq(currentOwner, newOwner, "Owner should have been changed by arbitrary caller");
    }
}
