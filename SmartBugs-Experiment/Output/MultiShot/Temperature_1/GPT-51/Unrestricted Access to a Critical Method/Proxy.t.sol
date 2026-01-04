
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Proxy} from "../src/Proxy.sol";

contract Target {
    bool public wasCalled;

    function markCalled() external {
        wasCalled = true;
    }
}

contract TestAccessControlProxy is Test {
    Proxy public _contractUnderTest;
    Target public target;

    function setUp() public {
        _contractUnderTest = new Proxy();
        target = new Target();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // Exclude the privileged role: the Proxy owner set in constructor
        vm.assume(caller != address(this));

        bytes memory data = abi.encodeWithSelector(Target.markCalled.selector);

        vm.prank(caller);
        _contractUnderTest.forward(address(target), data);

        assertTrue(target.wasCalled(), "Arbitrary caller could not trigger forward delegatecall");
    }
}
