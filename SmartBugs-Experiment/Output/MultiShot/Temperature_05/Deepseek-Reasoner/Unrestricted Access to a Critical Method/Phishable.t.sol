
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Phishable} from "../src/Phishable.sol";

contract TestAccessControlPhishable is Test {
    Phishable public _contractUnderTest;
    address public constant OWNER = address(0x123);

    function setUp() public {
        _contractUnderTest = new Phishable(OWNER);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        vm.assume(caller != OWNER);
        vm.assume(caller != address(_contractUnderTest));

        vm.deal(address(_contractUnderTest), 1 ether);

        vm.prank(caller, OWNER);
        _contractUnderTest.withdrawAll(payable(caller));

        assertEq(address(_contractUnderTest).balance, 0);
    }
}
