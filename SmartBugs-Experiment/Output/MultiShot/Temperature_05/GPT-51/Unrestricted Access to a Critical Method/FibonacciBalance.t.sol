
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {FibonacciBalance, FibonacciLib} from "../src/FibonacciBalance.sol";

contract TestAccessControlFibonacciBalance is Test {
    FibonacciBalance public _contractUnderTest;
    FibonacciLib public _lib;

    function setUp() public {
        _lib = new FibonacciLib();
        vm.deal(address(this), 100 ether);
        _contractUnderTest = new FibonacciBalance{value: 10 ether}(address(_lib));
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        vm.deal(caller, 1 ether);

        uint256 beforeCallerBalance = caller.balance;
        uint256 beforeContractBalance = address(_contractUnderTest).balance;

        vm.prank(caller);
        _contractUnderTest.withdraw();

        uint256 afterCallerBalance = caller.balance;
        uint256 afterContractBalance = address(_contractUnderTest).balance;

        assertGt(afterCallerBalance, beforeCallerBalance);
        assertLt(afterContractBalance, beforeContractBalance);
    }
}
