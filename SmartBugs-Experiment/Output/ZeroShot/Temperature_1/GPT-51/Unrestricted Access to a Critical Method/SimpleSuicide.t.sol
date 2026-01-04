
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
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);

        // No privileged roles exist in the contract, so no additional exclusions.

        // Fund the contract so selfdestruct has a visible effect
        vm.deal(address(simpleSuicide), 1 ether);

        // --- 2. Execution & Assertion ---
        vm.prank(caller);
        simpleSuicide.sudicideAnyone();

        // After selfdestruct, the contract code should be gone
        uint256 size;
        assembly {
            size := extcodesize(address(simpleSuicide))
        }
        assertEq(size, 0, "Contract should be destroyed by arbitrary caller");
    }
}
