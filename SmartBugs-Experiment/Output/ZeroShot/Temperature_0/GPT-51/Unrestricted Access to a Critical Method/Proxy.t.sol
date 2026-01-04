
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Proxy} from "../src/Proxy.sol";

contract Target {
    address public lastCaller;
    address public lastOrigin;

    function sensitive() external {
        lastCaller = msg.sender;
        lastOrigin = tx.origin;
    }
}

contract TestAccessControlProxy is Test {
    Proxy proxy;
    Target target;

    function setUp() public {
        proxy = new Proxy();
        target = new Target();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // Exclude the privileged role (proxy owner)
        vm.assume(caller != address(this));

        bytes memory data = abi.encodeWithSelector(Target.sensitive.selector);

        vm.prank(caller);
        proxy.forward(address(target), data);

        // Assert that the sensitive function was executed via an arbitrary caller
        assertEq(target.lastCaller(), address(proxy));
        assertEq(target.lastOrigin(), caller);
    }
}
