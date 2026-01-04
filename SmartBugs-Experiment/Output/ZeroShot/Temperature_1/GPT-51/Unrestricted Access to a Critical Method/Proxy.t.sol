
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Proxy} from "../src/Proxy.sol";

contract TestAccessControlProxy is Test {
    Proxy proxy;

    function setUp() public {
        proxy = new Proxy();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != address(proxy));

        DummyTarget target = new DummyTarget();

        vm.prank(caller);
        proxy.forward(address(target), abi.encodeWithSelector(DummyTarget.setValue.selector, 123));

        assertEq(target.value(), 123);
    }
}

contract DummyTarget {
    uint256 public value;

    function setValue(uint256 _value) public {
        value = _value;
    }
}
