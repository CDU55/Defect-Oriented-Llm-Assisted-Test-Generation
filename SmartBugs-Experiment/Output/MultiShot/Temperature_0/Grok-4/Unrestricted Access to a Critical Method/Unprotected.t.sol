
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
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        vm.assume(newOwner != address(0));
        vm.assume(newOwner != address(this));

        vm.prank(caller);
        _contractUnderTest.changeOwner(newOwner);

        address afterOwner = address(uint160(uint256(vm.load(address(_contractUnderTest), bytes32(uint256(0))))));
        assertEq(afterOwner, newOwner);
    }
}
