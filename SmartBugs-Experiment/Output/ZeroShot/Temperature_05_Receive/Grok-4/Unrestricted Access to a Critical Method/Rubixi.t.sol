
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Rubixi} from "../src/Rubixi.sol";

contract TestAccessControlRubixi is Test {
    Rubixi rubixi;
    address initialOwner;

    function setUp() public {
        rubixi = new Rubixi();
        initialOwner = makeAddr("initialOwner");
        vm.prank(initialOwner);
        rubixi.DynamicPyramid();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != initialOwner);

        vm.prank(caller);
        rubixi.DynamicPyramid();

        bytes32 creatorBytes = vm.load(address(rubixi), bytes32(uint256(5)));
        address newCreator = address(uint160(uint256(creatorBytes)));
        assertEq(newCreator, caller);
    }

    receive() external payable {}

    fallback() external payable {}
}
