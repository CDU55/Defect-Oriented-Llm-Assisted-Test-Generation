
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {StdStorage, stdStorage} from "../lib/forge-std/src/StdStorage.sol";
import {Rubixi} from "../src/Rubixi.sol";

contract TestAccessControlRubixi is Test {
    using stdStorage for StdStorage;
    
    Rubixi public rubixi;
    
    function setUp() public {
        rubixi = new Rubixi();
    }
    
    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        bytes memory code = address(caller).code;
        vm.assume(code.length == 0);
        
        vm.prank(caller);
        
        rubixi.DynamicPyramid();
        
        uint256 creatorSlot = stdstore
            .target(address(rubixi))
            .sig("creator()")
            .find();
        
        bytes32 creatorValue;
        assembly {
            creatorValue := sload(creatorSlot)
        }
        
        assertEq(address(uint160(uint256(creatorValue))), caller);
    }
}
