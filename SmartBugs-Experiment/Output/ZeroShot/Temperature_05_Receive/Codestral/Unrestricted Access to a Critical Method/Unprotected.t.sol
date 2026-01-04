
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Unprotected.sol";

contract TestAccessControlUnprotected is Test {
    Unprotected public unprotected;

    function setUp() public {
        unprotected = new Unprotected();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        vm.prank(caller);
        unprotected.changeOwner(caller);
    }

    receive() external payable {}

    fallback() external payable {}
}
