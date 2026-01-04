
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Phishable.sol";

contract TestAccessControlPhishable is Test {
    Phishable phishable;

    function setUp() public {
        phishable = new Phishable(address(this));
        vm.deal(address(phishable), 1 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != address(phishable.owner()));

        vm.prank(caller);
        phishable.withdrawAll(caller);

        assertEq(address(phishable).balance, 0);
    }
}
