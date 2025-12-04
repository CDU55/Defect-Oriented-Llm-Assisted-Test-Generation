
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SalaryManager} from "../src/SalaryManager.sol";

contract TestAccessControlSalaryManager is Test {
    SalaryManager salaryManager;

    function setUp() public {
        salaryManager = new SalaryManager();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        // 1. Caller cannot be the test contract itself (which is the owner).
        vm.assume(caller != address(this));
        // 2. Exclude the Zero Address
        vm.assume(caller != address(0));

        // 3. Exclude Foundry Internals (Dynamic)
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // --- 2. State Configuration ---
        
        // The function cancelContract requires: _totalAllocated < address(this).balance.
        // Initially, _totalAllocated is 0 and balance is 0.
        // We use vm.deal to add ETH to the contract without updating _totalAllocated, 
        // satisfying the condition (0 < 1 ether).
        vm.deal(address(salaryManager), 1 ether);

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // We simply call the function.
        // If vulnerable, this call succeeds (the caller gets the funds via selfdestruct).
        // If secure, it would revert.
        salaryManager.cancelContract();
    }
}
