
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
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // Exclude the deployer/owner of the proxy as a privileged role
        vm.assume(caller != address(this));

        // --- 2. State Configuration ---
        // No special state or funding required; forward is non-payable and has no checks.

        // --- 3. Execution & Assertion ---
        vm.prank(caller);

        // Call the critical method `forward` from an arbitrary, non-privileged address.
        // This should succeed because there is no access control.
        proxy.forward(address(0), "");
    }
}
