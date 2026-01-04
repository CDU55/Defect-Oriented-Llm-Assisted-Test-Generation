
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {FibonacciBalance, FibonacciLib} from "../src/FibonacciBalance.sol";

contract TestAccessControlFibonacciBalance is Test {
    FibonacciBalance public fibonacciBalance;
    FibonacciLib public fibonacciLib;

    function setUp() public {
        // Deploy the library contract first
        fibonacciLib = new FibonacciLib();
        
        // Deploy the FibonacciBalance contract with 10 ether
        fibonacciBalance = new FibonacciBalance{value: 10 ether}(address(fibonacciLib));
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        // Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // Exclude the Zero Address
        vm.assume(caller != address(0));

        // Exclude Foundry Internals
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the contract itself (cannot receive ether via transfer to itself)
        vm.assume(caller != address(fibonacciBalance));
        
        // The vulnerability is that there are NO privileged roles to exclude.
        // The withdraw function has no access control - anyone can call it.

        // --- 2. State Configuration ---
        
        // Ensure the caller can receive ether (make it a valid EOA or contract with receive)
        // For this test, we assume caller is an EOA that can receive ether
        
        // Record initial state
        uint256 initialWithdrawalCounter = fibonacciBalance.withdrawalCounter();
        uint256 initialContractBalance = address(fibonacciBalance).balance;
        uint256 initialCallerBalance = caller.balance;

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Call the withdraw function - this should succeed for ANY caller
        // demonstrating the unrestricted access vulnerability
        fibonacciBalance.withdraw();

        // Assert that the withdrawal actually happened
        // The withdrawal counter should have incremented
        assertEq(
            fibonacciBalance.withdrawalCounter(), 
            initialWithdrawalCounter + 1, 
            "Withdrawal counter should increment"
        );
        
        // The caller should have received ether (fibonacci of 1 with start=3 is 4 ether)
        // fibonacci(1) = start + 1 = 3 + 1 = 4
        uint256 expectedWithdrawal = 4 ether;
        assertEq(
            caller.balance, 
            initialCallerBalance + expectedWithdrawal, 
            "Caller should receive fibonacci amount"
        );
        
        // Contract balance should have decreased
        assertEq(
            address(fibonacciBalance).balance, 
            initialContractBalance - expectedWithdrawal, 
            "Contract balance should decrease"
        );
    }
}
