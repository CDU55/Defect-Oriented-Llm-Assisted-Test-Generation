
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {FibonacciBalance, FibonacciLib} from "../src/FibonacciBalance.sol";

contract TestAccessControlFibonacciBalance is Test {
    FibonacciBalance fibBalance;
    FibonacciLib fibLib;

    function setUp() public {
        fibLib = new FibonacciLib();
        fibBalance = new FibonacciBalance{value: 100 ether}(address(fibLib));
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        uint256 initialContractBalance = address(fibBalance).balance;
        uint256 initialCallerBalance = caller.balance;

        vm.deal(caller, 1 ether);

        vm.prank(caller);
        fibBalance.withdraw();

        assertLt(address(fibBalance).balance, initialContractBalance);
        assertGt(caller.balance, initialCallerBalance);
    }
}
