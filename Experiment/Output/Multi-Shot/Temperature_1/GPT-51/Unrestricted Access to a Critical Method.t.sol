
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
        // Exclude privileged role: the owner is the deployer (this test contract)
        vm.assume(caller != address(this));

        // --- 2. State Configuration ---

        // Fund the SalaryManager contract so that balance > 0
        vm.deal(address(_contractUnderTest), 10 ether);

        // Set some allocated amount so _totalAllocated < balance holds
        vm.prank(address(this));
        _contractUnderTest.sendSalary{value: 1 ether}(address(0xBEEF));

        // At this point:
        // balance = 10 ether
        // totalAllocated = 1 ether
        // So the invariant required by cancelContract holds:
        // _totalAllocated < address(this).balance

        // --- 3. Execution & Assertion ---

        // Switch context to the arbitrary, non-privileged caller
        vm.prank(caller);

        // Trigger vulnerability: arbitrary user can cancel and selfdestruct
        _contractUnderTest.cancelContract();
    }
}
