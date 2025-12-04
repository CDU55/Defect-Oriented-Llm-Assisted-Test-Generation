
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SalaryManager} from "../src/SalaryManager.sol";

contract TestAccessControlSalaryManager is Test {
    SalaryManager public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new SalaryManager();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // The owner is address(this) because it deployed the contract in setUp.
        // We exclude the owner to prove an arbitrary user can access the function.
        // Note: caller != address(this) is already checked above, but conceptually this is the privilege check.

        // --- 2. State Configuration ---
        
        // The target function cancelContract has a requirement:
        // require(_totalAllocated < address(this).balance, "Inconsistent state");
        // Initially _totalAllocated is 0. We need to ensure balance > 0.
        // We use vm.deal to inject funds directly without updating _totalAllocated.
        vm.deal(address(_contractUnderTest), 1 ether);

        // --- 3. Execution & Assertion ---
        
        vm.prank(caller);
        _contractUnderTest.cancelContract();
    }
}
