
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SalaryManager} from "../src/SalaryManager.sol";

contract TestAccessControlSalaryManager is Test {
    SalaryManager public _contractUnderTest;
    address private _owner;

    function setUp() public {
        _owner = address(this);
        _contractUnderTest = new SalaryManager();
        vm.deal(address(_contractUnderTest), 1 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the owner who deployed the contract
        vm.assume(caller != _owner);

        // --- 2. State Configuration ---
        
        // The cancelContract function requires: _totalAllocated < address(this).balance
        // Since we funded the contract with 1 ether and _totalAllocated is 0, this condition is met.
        
        // Store the contract's code to verify selfdestruct later
        uint256 contractBalanceBefore = address(_contractUnderTest).balance;
        
        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // The cancelContract function has no access control - any address can call it
        // This will succeed if the contract is vulnerable (which it is)
        _contractUnderTest.cancelContract();

        // Assert that the selfdestruct was executed by checking the balance was transferred
        // After selfdestruct, the contract's balance goes to the caller
        assertEq(caller.balance, contractBalanceBefore, "Caller should have received contract balance after selfdestruct");
    }
}
