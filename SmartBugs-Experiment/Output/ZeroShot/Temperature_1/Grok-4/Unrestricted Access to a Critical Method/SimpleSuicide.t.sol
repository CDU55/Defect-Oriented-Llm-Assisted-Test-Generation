
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SimpleSuicide} from "../src/SimpleSuicide.sol";

contract TestAccessControlSimpleSuicide is Test {
    SimpleSuicide public simpleSuicide;

    function setUp() public {
        simpleSuicide = new SimpleSuicide();
        vm.deal(address(simpleSuicide), 1 ether);
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm)); 
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // --- 2. State Configuration ---
        // Contract is funded in setUp

        // --- 3. Execution & Assertion ---
        uint256 contractBalanceBefore = address(simpleSuicide).balance;
        uint256 callerBalanceBefore = caller.balance;

        vm.prank(caller);
        simpleSuicide.sudicideAnyone();

        assertEq(address(simpleSuicide).balance, 0);
        assertEq(caller.balance, callerBalanceBefore + contractBalanceBefore);
        assertEq(address(simpleSuicide).code.length, 0);
    }
}
