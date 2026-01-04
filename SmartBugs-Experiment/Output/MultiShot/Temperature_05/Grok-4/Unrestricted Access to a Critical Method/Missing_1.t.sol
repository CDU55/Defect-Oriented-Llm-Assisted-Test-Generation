
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_1} from "../src/Missing_1.sol";

contract TestAccessControlMissing_1 is Test {
    Missing_1 public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Missing_1();
        _contractUnderTest.IamMissing();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the current owner to prove non-owner can change it
        address currentOwner = address(uint160(uint256(vm.load(address(_contractUnderTest), bytes32(0)))));
        vm.assume(caller != currentOwner);

        vm.prank(caller);
        _contractUnderTest.IamMissing();

        // Assert the owner has been changed to the caller
        address newOwner = address(uint160(uint256(vm.load(address(_contractUnderTest), bytes32(0)))));
        assertEq(newOwner, caller);
    }
}
