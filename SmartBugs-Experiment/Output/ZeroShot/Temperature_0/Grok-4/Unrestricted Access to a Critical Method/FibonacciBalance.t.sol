
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {FibonacciBalance, FibonacciLib} from "../src/FibonacciBalance.sol";

contract TestAccessControlFibonacciBalance is Test {
    FibonacciLib public fibLib;
    FibonacciBalance public fibBalance;

    function setUp() public {
        fibLib = new FibonacciLib();
        uint startVal = uint(uint160(address(fibLib)));
        uint fib1 = startVal + 1;
        uint amount = fib1 * 1 ether;
        fibBalance = new FibonacciBalance(address(fibLib));
        vm.deal(address(fibBalance), amount);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // --- 2. State Configuration ---
        
        // --- 3. Execution & Assertion ---
        uint startVal = uint(uint160(address(fibLib)));
        uint fib1 = startVal + 1;
        uint expected = fib1 * 1 ether;

        uint balBefore = caller.balance;
        vm.prank(caller);
        fibBalance.withdraw();
        uint balAfter = caller.balance;
        assertEq(balAfter, balBefore + expected);
    }
}
