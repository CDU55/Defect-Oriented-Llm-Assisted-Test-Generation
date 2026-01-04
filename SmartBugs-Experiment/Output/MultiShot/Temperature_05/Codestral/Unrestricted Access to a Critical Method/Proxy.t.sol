
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Proxy.sol";

contract TestAccessControlProxy is Test {
    Proxy public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Proxy();
    }

    function test_highlightArbitraryUserCanAccess(address caller, address callee, bytes memory data) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != _contractUnderTest.owner());

        vm.prank(caller);
        _contractUnderTest.forward(callee, data);
    }
}
