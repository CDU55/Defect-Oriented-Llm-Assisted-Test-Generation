
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {FibonacciBalance} from "../src/FibonacciBalance.sol";
import {FibonacciLib} from "../src/FibonacciLib.sol";

contract TestAccessControlFibonacciBalance is Test {
    FibonacciBalance public fibBalance;
    FibonacciLib public fibLib;
    
    function setUp() public {
        fibLib = new FibonacciLib();
        fibBalance = new FibonacciBalance{value: 10 ether}(address(fibLib));
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        vm.deal(caller, 1 ether);
        
        uint256 initialBalance = address(caller).balance;
        
        vm.prank(caller);
        fibBalance.withdraw();
        
        uint256 finalBalance = address(caller).balance;
        
        assertTrue(finalBalance > initialBalance, "Arbitrary user successfully withdrew funds");
    }
}
