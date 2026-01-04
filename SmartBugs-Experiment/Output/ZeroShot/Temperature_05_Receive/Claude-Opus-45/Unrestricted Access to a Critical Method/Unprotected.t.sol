
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Unprotected} from "../src/Unprotected.sol";

contract TestAccessControlUnprotected is Test {
    Unprotected private unprotected;
    address private originalOwner;

    function setUp() public {
        originalOwner = address(this);
        unprotected = new Unprotected();
    }

    function test_highlightArbitraryUserCanAccess(address caller, address newOwner) public {
        
        // --- 1. Constraints ---
        // Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // Exclude the Zero Address
        vm.assume(caller != address(0));

        // Exclude Foundry Internals (Dynamic)
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // CRITICAL - Exclude ALL privileged roles.
        // The original owner is the test contract (address(this)), already excluded above.
        // No other privileged roles exist in this contract.

        // Constrain newOwner to be a valid address
        vm.assume(newOwner != address(0));

        // --- 2. State Configuration ---
        
        // No funding needed - changeOwner is not payable
        // No special state setup required - the vulnerability exists in the default state

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        // If the contract is VULNERABLE (Unprotected), this call will SUCCEED, and the test will PASS.
        // If the contract is SECURE (Protected), this call will REVERT, and the test will FAIL.
        unprotected.changeOwner(newOwner);

        // ASSERT SUCCESS
        // Verify the owner was actually changed by reading the private owner variable
        // The owner is stored at slot 0
        bytes32 ownerSlot = vm.load(address(unprotected), bytes32(uint256(0)));
        address currentOwner = address(uint160(uint256(ownerSlot)));
        
        assertEq(currentOwner, newOwner, "Owner should have been changed by arbitrary caller");
        assertTrue(caller != originalOwner, "Caller was not the original owner, proving unauthorized access");
    }

    receive() external payable {}

    fallback() external payable {}
}
