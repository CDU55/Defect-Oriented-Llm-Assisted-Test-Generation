
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_2} from "../src/Missing_2.sol";

contract TestAccessControlMissing_2 is Test {
    Missing_2 missing2;

    function setUp() public {
        missing2 = new Missing_2();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // No privileged roles are defined before calling `missing()`,
        // so there is nothing to exclude beyond generic constraints.

        // --- 2. State Configuration ---
        // No special state or funding required to call `missing()`.

        // --- 3. Execution & Assertion ---
        vm.prank(caller);
        missing2.missing();

        // Optional: we could later show that `caller` can now withdraw,
        // but for this test we only need to prove arbitrary access to `missing()`.
    }
}
