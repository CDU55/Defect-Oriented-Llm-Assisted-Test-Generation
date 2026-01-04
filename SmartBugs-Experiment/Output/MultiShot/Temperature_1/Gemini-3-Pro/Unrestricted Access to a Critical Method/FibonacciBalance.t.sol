
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {FibonacciBalance, FibonacciLib} from "../src/FibonacciBalance.sol";

contract TestAccessControlFibonacciBalance is Test {
    FibonacciBalance public _contractUnderTest;
    FibonacciLib public _lib;

    function setUp() public {
        _lib = new FibonacciLib();
        _contractUnderTest = new FibonacciBalance(address(_lib));
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // Due to storage collision between FibonacciBalance and FibonacciLib:
        // Slot 0 in Balance is 'fibonacciLibrary' (address).
        // Slot 0 in Lib is 'start' (uint).
        // When delegatecall happens, Lib reads 'start' as the address of the library.
        uint256 startVal = uint256(uint160(address(_lib)));
        
        // withdraw() increments counter to 1, calling fibonacci(1).
        // fibonacci(1) returns start + 1.
        uint256 amountToWithdraw = (startVal + 1) * 1 ether;

        // Fund the contract to ensure the withdrawal succeeds despite the massive amount
        vm.deal(address(_contractUnderTest), amountToWithdraw);

        vm.prank(caller);
        _contractUnderTest.withdraw();
    }
}
