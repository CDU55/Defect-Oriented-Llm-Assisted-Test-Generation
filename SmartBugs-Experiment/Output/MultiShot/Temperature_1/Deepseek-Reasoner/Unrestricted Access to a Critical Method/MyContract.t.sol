
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract TestAccessControlMyContract is Test {
    MyContract public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new MyContract();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        vm.assume(caller != _contractUnderTest.owner());

        vm.prank(caller);
        
        address payable receiver = payable(address(0x123));
        uint256 amount = 0;
        _contractUnderTest.sendTo(receiver, amount);
    }
}
