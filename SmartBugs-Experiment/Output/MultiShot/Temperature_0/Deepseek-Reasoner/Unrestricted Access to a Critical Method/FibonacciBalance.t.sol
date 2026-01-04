
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {FibonacciBalance} from "../src/FibonacciBalance.sol";
import {FibonacciLib} from "../src/FibonacciLib.sol";

contract TestAccessControlFibonacciBalance is Test {
    FibonacciBalance public _contractUnderTest;
    FibonacciLib public fibLib;
    
    function setUp() public {
        fibLib = new FibonacciLib();
        vm.deal(address(this), 100 ether);
        _contractUnderTest = new FibonacciBalance{value: 100 ether}(address(fibLib));
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        uint256 contractBalanceBefore = address(_contractUnderTest).balance;
        uint256 callerBalanceBefore = caller.balance;

        vm.prank(caller);
        _contractUnderTest.withdraw();

        uint256 contractBalanceAfter = address(_contractUnderTest).balance;
        uint256 callerBalanceAfter = caller.balance;
        
        assertLt(contractBalanceAfter, contractBalanceBefore);
        assertGt(callerBalanceAfter, callerBalanceBefore);
    }
}
