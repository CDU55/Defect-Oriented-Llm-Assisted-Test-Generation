
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Proxy} from "../src/Proxy.sol";

contract TestAccessControlProxy is Test {
    Proxy proxy;

    function setUp() public {
        proxy = new Proxy();
    }

    function test_highlightArbitraryUserCanAccess(address caller, address callee, bytes calldata _data) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));

        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        vm.assume(caller != proxy.owner());

        vm.assume(callee < address(1) || callee > address(9));
        vm.assume(address(callee).code.length == 0);

        // --- 2. State Configuration ---
        
        // --- 3. Execution & Assertion ---
        
        vm.prank(caller);

        proxy.forward(callee, _data);
    }
}
