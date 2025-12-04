
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SalaryManager} from "../src/SalaryManager.sol";

contract TestAccessControlSalaryManager is Test {
    SalaryManager public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new SalaryManager();
        // Fund the contract so that address(this).balance > _totalAllocated (which is 0)
        vm.deal(address(_contractUnderTest), 10 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // Exclude privileged role: the owner is the deployer (this contract)
        vm.assume(caller != address(this));

        // --- 2. State Configuration ---
        // No additional state needed: _totalAllocated is 0 and contract has balance,
        // so _totalAllocated < address(this).balance holds.

        // --- 3. Execution & Assertion ---
        vm.prank(caller);
        _contractUnderTest.cancelContract();
    }
}
