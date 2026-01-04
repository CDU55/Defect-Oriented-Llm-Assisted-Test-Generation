
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Unprotected} from "../src/Unprotected.sol";

contract TestAccessControlUnprotected is Test {
    Unprotected unprotected;

    function setUp() public {
        unprotected = new Unprotected();
    }

    function test_highlightArbitraryUserCanAccess(address caller, address newOwner) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        address currentOwner = address(uint160(uint256(vm.load(address(unprotected), bytes32(uint256(0))))));
        vm.assume(caller != currentOwner);

        vm.assume(newOwner != address(0));
        vm.assume(newOwner != currentOwner);

        // --- 2. State Configuration ---
        

        // --- 3. Execution & Assertion ---
        
        vm.prank(caller);

        unprotected.changeOwner(newOwner);
        
        assertEq(
            address(uint160(uint256(vm.load(address(unprotected), bytes32(uint256(0)))))), 
            newOwner
        );
    }

    receive() external payable {}

    fallback() external payable {}
}
