
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_2} from "../src/Missing_2.sol";

contract TestAccessControlMissing_2 is Test {
    Missing_2 missing2;

    function setUp() public {
        missing2 = new Missing_2();
        missing2.missing();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        address currentOwner = address(uint160(uint256(vm.load(address(missing2), bytes32(uint256(0))))));
        vm.assume(caller != currentOwner);

        // --- 2. State Configuration ---
        

        // --- 3. Execution & Assertion ---
        
        vm.prank(caller);
        missing2.missing();

        bytes32 ownerSlot = vm.load(address(missing2), bytes32(uint256(0)));
        address newOwner = address(uint160(uint256(ownerSlot)));
        assertEq(newOwner, caller);
    }

    receive() external payable {}

    fallback() external payable {}
}
