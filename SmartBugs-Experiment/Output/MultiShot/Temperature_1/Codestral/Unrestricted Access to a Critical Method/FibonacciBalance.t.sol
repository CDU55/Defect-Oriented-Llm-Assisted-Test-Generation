
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";

contract TestAccessControlFibonacciBalance is Test {
    FibonacciBalance public _contractUnderTest;
    FibonacciLib public _fibonacciLib;

    function setUp() public {
        _fibonacciLib = new FibonacciLib();
        vm.deal(address(_fibonacciLib), 100 ether);
        _contractUnderTest = new FibonacciBalance(address(_fibonacciLib));
        vm.deal(address(_contractUnderTest), 100 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        vm.prank(caller);
        _contractUnderTest.withdraw();
    }
}
