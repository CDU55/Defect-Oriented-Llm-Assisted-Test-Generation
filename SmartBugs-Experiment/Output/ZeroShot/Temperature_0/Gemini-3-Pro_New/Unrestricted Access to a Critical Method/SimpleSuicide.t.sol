
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SimpleSuicide} from "../src/SimpleSuicide.sol";

contract TestAccessControlSimpleSuicide is Test {

    SimpleSuicide simpleSuicide;

    function setUp() public {
        simpleSuicide = new SimpleSuicide();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        // 1. Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // 2. Exclude the Zero Address
        vm.assume(caller != address(0));

        // 3. Exclude Foundry Internals (Dynamic)
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // There are no privileged roles defined in SimpleSuicide to exclude.

        // --- 2. State Configuration ---
        
        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // We simply call the function.
        // If the contract is VULNERABLE (Unprotected), this call will SUCCEED, and the test will PASS.
        simpleSuicide.sudicideAnyone();
    }
}
