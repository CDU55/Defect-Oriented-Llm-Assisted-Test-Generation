
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

        // Exclude the (only) privileged role: the current owner.
        // Since owner is private and initially zero, we first set it via missing()
        // as this contract, then exclude this contract address above.
        // This ensures `caller` is not the authorized owner.
        missing2.missing();
        vm.assume(caller != address(this));

        // --- 2. State Configuration ---
        // No additional state required; missing() is public and unrestricted.

        // --- 3. Execution & Assertion ---
        vm.prank(caller);
        missing2.missing();

        // Optional assertion: owner should now be `caller` and able to withdraw.
        // This confirms that an arbitrary address gained the privileged role.
        vm.deal(address(missing2), 1 ether);

        vm.prank(caller);
        missing2.withdraw();

        assertEq(caller.balance, 1 ether);
    }
}
