
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Missing_2} from "../src/Missing_2.sol";

contract TestAccessControlMissing_2 is Test {
    Missing_2 missing2;

    function setUp() public {
        missing2 = new Missing_2();
        missing2.missing();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        vm.deal(address(this), 1 ether);
        payable(address(missing2)).transfer(1 ether);
        assertEq(address(missing2).balance, 1 ether);

        vm.prank(caller);
        missing2.missing();

        uint256 initialCallerBalance = caller.balance;

        vm.prank(caller);
        missing2.withdraw();

        assertEq(address(missing2).balance, 0);
        assertEq(caller.balance, initialCallerBalance + 1 ether);
    }
}
