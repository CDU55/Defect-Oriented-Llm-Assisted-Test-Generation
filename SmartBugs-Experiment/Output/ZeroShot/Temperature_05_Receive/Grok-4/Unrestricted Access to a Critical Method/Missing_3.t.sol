
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_3} from "../src/Missing_3.sol";

contract TestAccessControlMissing_3 is Test {
    Missing_3 missing_3;

    function setUp() public {
        missing_3 = new Missing_3();
        missing_3.Constructor();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        vm.prank(caller);
        missing_3.Constructor();

        bytes32 ownerData = vm.load(address(missing_3), bytes32(uint256(0)));
        assertEq(address(uint160(uint256(ownerData))), caller);
    }

    receive() external payable {}

    fallback() external payable {}
}
