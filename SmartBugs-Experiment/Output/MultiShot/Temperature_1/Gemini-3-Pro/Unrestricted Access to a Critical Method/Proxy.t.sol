
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Proxy} from "../src/Proxy.sol";

contract TargetLogic {
    function doSomething() external pure {}
}

contract TestAccessControlProxy is Test {
    Proxy public _contractUnderTest;
    TargetLogic public _logic;

    function setUp() public {
        _contractUnderTest = new Proxy();
        _logic = new TargetLogic();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the owner. Since 'this' contract deployed Proxy, 'this' is the owner.
        // The constraint `caller != address(this)` above covers this.

        // --- 2. State Configuration ---
        // No specific state or funding required for this vulnerability.

        // --- 3. Execution & Assertion ---
        
        vm.prank(caller);

        // Trigger Vulnerability
        // The forward function allows arbitrary execution via delegatecall.
        // If the contract is vulnerable, this call will succeed.
        _contractUnderTest.forward(address(_logic), abi.encodeWithSelector(TargetLogic.doSomething.selector));
    }
}
