
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_2} from "../src/Missing_2.sol";

contract TestAccessControlMissing_2 is Test {
    Missing_2 missingContract;

    function setUp() public {
        missingContract = new Missing_2();
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
        // The owner is initially address(0), which is already excluded.
        // If the owner were set to another address, we would exclude it here.

        // --- 2. State Configuration ---
        
        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        missingContract.missing();
        
        // ASSERT SUCCESS
        // Verify that the caller has successfully become the owner.
        // 'owner' is the first state variable (slot 0).
        bytes32 ownerSlot = vm.load(address(missingContract), bytes32(uint256(0)));
        address storedOwner = address(uint160(uint256(ownerSlot)));
        
        assertEq(storedOwner, caller, "Arbitrary caller should be able to take ownership via missing()");
    }

    receive() external payable {}

    fallback() external payable {}
}
