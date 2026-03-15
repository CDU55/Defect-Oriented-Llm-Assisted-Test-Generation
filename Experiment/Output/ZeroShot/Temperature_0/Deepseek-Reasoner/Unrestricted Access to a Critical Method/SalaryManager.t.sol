// Generation Time: 59,63s
// Input Tokens: 2515
// Output Tokens: 275
// Reasoning Tokens: 2344


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SalaryManager} from "../src/SalaryManager.sol";

contract TestAccessControlSalaryManager is Test {

    SalaryManager private salaryManager;

    function setUp() public {
        salaryManager = new SalaryManager();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        address owner = address(this);
        vm.assume(caller != owner);

        vm.deal(address(salaryManager), 1 ether);

        uint256 contractBalanceBefore = address(salaryManager).balance;
        uint256 callerBalanceBefore = caller.balance;

        vm.prank(caller);
        salaryManager.cancelContract();

        uint256 callerBalanceAfter = caller.balance;
        
        assertEq(callerBalanceAfter, callerBalanceBefore + contractBalanceBefore);
    }
}
