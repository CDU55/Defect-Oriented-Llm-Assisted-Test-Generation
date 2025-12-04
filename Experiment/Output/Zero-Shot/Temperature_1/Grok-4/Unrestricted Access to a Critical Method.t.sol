
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
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // --- 2. State Configuration ---
        vm.deal(address(salaryManager), 1 ether);

        // --- 3. Execution & Assertion ---
        uint256 callerBalanceBefore = caller.balance;
        uint256 contractBalanceBefore = address(salaryManager).balance;

        vm.prank(caller);
        salaryManager.cancelContract();

        assertEq(address(salaryManager).balance, 0);
        assertEq(caller.balance, callerBalanceBefore + contractBalanceBefore);
    }
}
