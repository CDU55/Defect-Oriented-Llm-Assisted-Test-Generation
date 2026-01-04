
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_2} from "../src/Missing_2.sol";

contract TestAccessControlMissing_2 is Test {
    Missing_2 public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Missing_2();
        _contractUnderTest.missing();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        address currentOwner = address(uint160(vm.load(address(_contractUnderTest), bytes32(0))));
        vm.assume(caller != currentOwner);

        vm.prank(caller);
        _contractUnderTest.missing();

        address newOwner = address(uint160(vm.load(address(_contractUnderTest), bytes32(0))));
        assertEq(newOwner, caller);
    }
}
