
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_2} from "../src/Missing_2.sol";

contract TestAccessControlMissing_2 is Test {
    Missing_2 target;

    function setUp() public {
        target = new Missing_2();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        vm.prank(caller);
        target.missing();

        address currentOwner = address(uint160(uint256(vm.load(address(target), bytes32(0)))));
        assertEq(currentOwner, caller);
    }

    receive() external payable {}

    fallback() external payable {}
}
