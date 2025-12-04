
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_3} from "../src/Missing_3.sol";

contract TestAccessControlMissing_3 is Test {

    Missing_3 missing_3;

    function setUp() public {
        missing_3 = new Missing_3();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // The function 'Constructor' is public and not a real constructor (wrong casing/syntax for 0.8.x),
        // allowing anyone to call it and become the owner.
        missing_3.Constructor();

        // Verify side effects: Caller should now be owner and able to withdraw
        vm.prank(caller);
        missing_3.withdraw();
    }
}
