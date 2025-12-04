
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SalaryManager} from "../src/SalaryManager.sol";

contract TestAccessControlSalaryManager is Test {
    SalaryManager salaryManager;
    address owner;

    function setUp() public {
        owner = address(this);
        salaryManager = new SalaryManager();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the owner to prove that a non-privileged user can access the function
        vm.assume(caller != owner);

        // --- 2. State Configuration ---
        
        // The cancelContract function requires _totalAllocated < address(this).balance.
        // _totalAllocated starts at 0. We inject ETH directly into the contract to satisfy the condition.
        vm.deal(address(salaryManager), 10 ether);

        // --- 3. Execution & Assertion ---
        
        vm.prank(caller);
        salaryManager.cancelContract();
    }
}
