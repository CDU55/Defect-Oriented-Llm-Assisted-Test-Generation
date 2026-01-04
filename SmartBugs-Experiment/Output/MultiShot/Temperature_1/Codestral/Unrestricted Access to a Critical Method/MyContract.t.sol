
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/MyContract.sol";

contract TestAccessControlMyContract is Test {

    MyContract public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new MyContract();
    }

    function test_highlightArbitraryUserCanAccess(address caller, address payable receiver, uint amount) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != _contractUnderTest.owner());
        vm.assume(amount > 0);

        vm.deal(caller, amount);

        vm.prank(caller);
        _contractUnderTest.sendTo(receiver, amount);
    }
}
