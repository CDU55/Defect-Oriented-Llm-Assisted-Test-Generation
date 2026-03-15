// Generation Time: 58,01s
// Input Tokens: 2610
// Output Tokens: 291
// Reasoning Tokens: 2309


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
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        address owner = address(this);
        vm.assume(caller != owner);

        uint256 contractBalance = 1 ether;
        vm.deal(address(_contractUnderTest), contractBalance);

        uint256 callerBalanceBefore = caller.balance;
        uint256 contractBalanceBefore = address(_contractUnderTest).balance;

        vm.prank(caller);
        _contractUnderTest.cancelContract();

        uint256 callerBalanceAfter = caller.balance;
        assertEq(callerBalanceAfter, callerBalanceBefore + contractBalanceBefore);
    }
}
