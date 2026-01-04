
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";

contract TestAccessControlSimpleSuicide is Test {
    SimpleSuicide public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new SimpleSuicide();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        uint256 codeSizeBefore = address(_contractUnderTest).code.length;
        assertGt(codeSizeBefore, 0);

        vm.prank(caller);
        _contractUnderTest.sudicideAnyone();

        uint256 codeSizeAfter = address(_contractUnderTest).code.length;
        assertEq(codeSizeAfter, 0);
    }
}
