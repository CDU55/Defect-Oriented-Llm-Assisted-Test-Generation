
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SimpleSuicide} from "../src/SimpleSuicide.sol";

contract TestAccessControlSimpleSuicide is Test {
    SimpleSuicide simpleSuicide;

    function setUp() public {
        simpleSuicide = new SimpleSuicide();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        vm.deal(caller, 1 ether);

        bool preExists = address(simpleSuicide).code.length > 0;
        assertTrue(preExists, "Contract should exist before selfdestruct");

        vm.prank(caller);
        simpleSuicide.sudicideAnyone();

        bool postExists = address(simpleSuicide).code.length > 0;
        assertFalse(postExists, "Contract should be destroyed by arbitrary caller");
    }

    receive() external payable {}

    fallback() external payable {}
}
