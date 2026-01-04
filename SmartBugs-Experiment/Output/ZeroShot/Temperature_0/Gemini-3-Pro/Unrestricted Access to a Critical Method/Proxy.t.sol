
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
        // 1. Caller cannot be the test contract itself (which is the owner).
        vm.assume(caller != address(this));
        // 2. Exclude the Zero Address
        vm.assume(caller != address(0));

        // 3. Exclude Foundry Internals (Dynamic)
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // 2. CRITICAL - Exclude ALL privileged roles.
        // The constructor sets owner = msg.sender. In setUp, msg.sender is this test contract.
        // We have already excluded address(this) above.

        // --- 2. State Configuration ---
        
        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        // We call forward with an arbitrary address (EOA) and empty data.
        // delegatecall to an address with no code returns true, satisfying the internal require(success).
        // If the contract is VULNERABLE (Unprotected), this call will SUCCEED.
        proxy.forward(address(0x1337), "");
    }
}
