
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Proxy} from "../src/Proxy.sol";

contract TestAccessControlProxy is Test {
    Proxy public _contractUnderTest;

    address public owner;

    function setUp() public {
        owner = address(this);
        _contractUnderTest = new Proxy();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != owner);

        vm.prank(caller);

        address callee = address(0xdead);
        bytes memory data = abi.encodeWithSignature("nonExistentFunction()");

        // The vulnerability is that any arbitrary caller can invoke `forward`
        // without any access control. We only care that the call is reachable
        // by an unprivileged user; the delegatecall itself may revert.
        try this.callForward(_contractUnderTest, callee, data) {
            // If it does not revert, it clearly shows arbitrary access.
        } catch {
            // Even if the internal delegatecall reverts, the lack of access
            // control is demonstrated by the fact that `forward` was callable
            // by an arbitrary address (no owner check).
        }
    }

    function callForward(Proxy proxy, address callee, bytes memory data) public {
        proxy.forward(callee, data);
    }
}
