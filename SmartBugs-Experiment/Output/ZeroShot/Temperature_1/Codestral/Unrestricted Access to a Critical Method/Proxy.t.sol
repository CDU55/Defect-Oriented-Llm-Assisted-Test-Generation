
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Proxy.sol";

contract TestAccessControlProxy is Test {
    Proxy proxy;
    address owner;
    address attacker;

    function setUp() public {
        owner = makeAddr("owner");
        proxy = new Proxy();
        vm.prank(owner);
        vm.assume(owner != address(0));
        vm.assume(owner != address(this));
        vm.assume(owner != address(vm));
        vm.assume(owner != 0x000000000000000000636F6e736F6c652e6c6f67);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != owner);

        vm.prank(caller);

        address callee = makeAddr("callee");
        bytes memory data = abi.encodeWithSignature("test()");

        proxy.forward(callee, data);
    }
}
