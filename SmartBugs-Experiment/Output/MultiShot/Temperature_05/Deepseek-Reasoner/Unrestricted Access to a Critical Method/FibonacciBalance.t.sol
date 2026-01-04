
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {FibonacciBalance} from "../src/FibonacciBalance.sol";
import {FibonacciLib} from "../src/FibonacciBalance.sol";

contract TestAccessControlFibonacciBalance is Test {
    FibonacciBalance public _contractUnderTest;
    FibonacciLib public _fibonacciLib;
    
    function setUp() public {
        _fibonacciLib = new FibonacciLib();
        vm.deal(address(this), 100 ether);
        _contractUnderTest = new FibonacciBalance{value: 10 ether}(address(_fibonacciLib));
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        uint256 contractInitialBalance = address(_contractUnderTest).balance;
        uint256 callerInitialBalance = caller.balance;
        
        vm.prank(caller);
        _contractUnderTest.withdraw();
        
        uint256 callerFinalBalance = caller.balance;
        uint256 contractFinalBalance = address(_contractUnderTest).balance;
        
        assertTrue(callerFinalBalance > callerInitialBalance, "Caller balance should increase");
        assertTrue(contractFinalBalance < contractInitialBalance, "Contract balance should decrease");
    }
}
