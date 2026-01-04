
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Rubixi} from "../src/Rubixi.sol";

contract TestAccessControlRubixi is Test {
    Rubixi public _contractUnderTest;
    address initialOwner;

    function setUp() public {
        _contractUnderTest = new Rubixi();
        initialOwner = makeAddr("initialOwner");
        vm.prank(initialOwner);
        _contractUnderTest.DynamicPyramid();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != initialOwner);

        vm.prank(caller);
        _contractUnderTest.DynamicPyramid();

        address newCreator = address(uint160(uint256(vm.load(address(_contractUnderTest), bytes32(uint256(5))))));
        assertEq(newCreator, caller);
    }
}
