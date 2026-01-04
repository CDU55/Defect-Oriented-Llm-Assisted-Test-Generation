
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Unprotected} from "../src/Unprotected.sol";

contract TestAccessControlUnprotected is Test {
    Unprotected private unprotected;
    address private legitimateOwner;

    function setUp() public {
        legitimateOwner = address(this);
        unprotected = new Unprotected();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // --- 1. Constraints ---
        // Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // Exclude the Zero Address
        vm.assume(caller != address(0));

        // Exclude Foundry Internals
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the legitimate owner (the deployer of the contract)
        vm.assume(caller != legitimateOwner);

        // --- 2. State Configuration ---
        // No special state configuration needed for this test.
        // The contract is deployed with this test contract as the owner.

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        // An arbitrary user attempts to change the owner to themselves.
        // If the contract is VULNERABLE (Unprotected), this call will SUCCEED, and the test will PASS.
        // If the contract is SECURE (Protected), this call will REVERT, and the test will FAIL.
        unprotected.changeOwner(caller);

        // ASSERT SUCCESS
        // Verify the owner was actually changed by reading the private storage slot.
        // The owner is stored at slot 0 in the contract.
        bytes32 ownerSlot = vm.load(address(unprotected), bytes32(uint256(0)));
        address newOwner = address(uint160(uint256(ownerSlot)));
        
        // Confirm the arbitrary caller successfully became the owner
        assertEq(newOwner, caller, "Vulnerability confirmed: arbitrary user changed owner");
    }
}
