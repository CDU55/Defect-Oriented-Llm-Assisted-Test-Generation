
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Unprotected} from "../src/Unprotected.sol";

contract TestAccessControlUnprotected is Test {
    Unprotected public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Unprotected();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        vm.assume(caller != address(this));
        vm.assume(caller != _contractUnderTest.owner());

        address newOwner = address(0x1234567890123456789012345678901234567890);
        
        vm.prank(caller);
        _contractUnderTest.changeOwner(newOwner);

        bytes32 slot0 = vm.load(address(_contractUnderTest), bytes32(uint256(0)));
        address actualOwner = address(uint160(uint256(slot0)));
        
        assertEq(actualOwner, newOwner, "Owner should be changed by arbitrary caller");
    }
}
