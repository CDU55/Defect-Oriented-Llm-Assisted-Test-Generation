
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/FibonacciBalance.sol";
import "../src/FibonacciLib.sol";

contract TestAccessControlFibonacciBalance is Test {
    FibonacciBalance public fibonacciBalance;
    FibonacciLib public fibonacciLib;

    function setUp() public {
        fibonacciLib = new FibonacciLib();
        fibonacciBalance = new FibonacciBalance(address(fibonacciLib));
        fibonacciLib.setStart(3);
        fibonacciLib.setFibonacci(3);
        vm.deal(address(fibonacciBalance), 100 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        vm.prank(caller);
        fibonacciBalance.withdraw();
    }
}
