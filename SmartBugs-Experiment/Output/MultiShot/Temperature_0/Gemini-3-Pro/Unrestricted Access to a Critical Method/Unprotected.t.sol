
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Unprotected} from "../src/Unprotected.sol";

contract TestAccessControlUnprotected is Test {
    Unprotected public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Unprotected();
    }

    function test_highlightArbitraryUserCanAccess(address caller, address newOwner) public {
        
        // --- 1. Constraints ---
        // Caller cannot be the test contract itself (which is the owner in this context)
        vm.assume(caller != address(this));
        // Exclude the Zero Address
        vm.assume(caller != address(0));

        // Exclude Foundry Internals
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude privileged roles. 
        // In setUp(), address(this) deployed the contract, so address(this) is the owner.
        // The check `caller != address(this)` handles this exclusion.

        // Constrain fuzz args
        vm.assume(newOwner != address(0));

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Trigger Vulnerability: Call changeOwner without being the owner
        _contractUnderTest.changeOwner(newOwner);

        // Assert Success: Verify the owner was actually changed.
        // Since 'owner' is private and at slot 0, we load it directly from storage.
        bytes32 ownerSlot = vm.load(address(_contractUnderTest), bytes32(uint256(0)));
        address storedOwner = address(uint160(uint256(ownerSlot)));
        
        assertEq(storedOwner, newOwner);
    }
}
