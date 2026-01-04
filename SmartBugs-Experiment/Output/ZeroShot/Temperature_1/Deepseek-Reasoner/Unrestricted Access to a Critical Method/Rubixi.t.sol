
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Rubixi} from "../src/Rubixi.sol";
import {stdStorage, StdStorage} from "../lib/forge-std/src/StdStorage.sol";

contract TestAccessControlRubixi is Test {
    using stdStorage for StdStorage;
    
    Rubixi private rubixi;

    function setUp() public {
        rubixi = new Rubixi();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        uint256 slot = 5;
        address currentCreator = address(uint160(uint256(vm.load(address(rubixi), bytes32(slot)))));
        vm.assume(caller != currentCreator);

        vm.prank(caller);
        rubixi.DynamicPyramid();

        address newCreator = address(uint160(uint256(vm.load(address(rubixi), bytes32(slot)))));
        
        assertEq(newCreator, caller);
    }
}
