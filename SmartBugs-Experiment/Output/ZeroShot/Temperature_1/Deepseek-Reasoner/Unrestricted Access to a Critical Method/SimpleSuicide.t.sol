
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
        
        uint256 contractBalanceBefore = address(simpleSuicide).balance;
        uint256 callerBalanceBefore = caller.balance;
        
        if (contractBalanceBefore > 0) {
            assertEq(
                callerBalanceBefore + contractBalanceBefore,
                caller.balance,
                "Caller should receive contract balance after selfdestruct"
            );
        }
        
        vm.prank(caller);
        simpleSuicide.sudicideAnyone();
        
        uint256 codeSize = address(simpleSuicide).code.length;
        assertEq(codeSize, 0, "Contract should be destroyed after selfdestruct");
    }
}
