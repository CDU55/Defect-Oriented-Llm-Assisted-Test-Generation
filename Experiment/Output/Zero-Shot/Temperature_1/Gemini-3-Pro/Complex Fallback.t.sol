
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Crowdfund} from "../src/Crowdfund.sol";

contract TestComplexFallbackCrowdfund is Test {
    Crowdfund crowdfund;

    function setUp() public {
        crowdfund = new Crowdfund();
    }

    function test_highlightGasNeededIsOver2300(uint256 amount) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(amount > 0.01 ether && amount < type(uint128).max);

        // --- 2. State Configuration ---
        address sender = makeAddr("sender");
        vm.deal(sender, amount * 2);

        // Fund the Test Contract (Safety Net)
        vm.deal(address(this), amount * 2);

        // --- 3. Measure Gas Consumption ---
        
        vm.prank(sender);
        uint256 gasBefore = gasleft();
        
        // We use .call to allow execution to proceed even if it costs more than 2300 gas,
        // so we can measure the actual consumption. Standard .transfer/.send would revert immediately.
        (bool success, ) = address(crowdfund).call{value: amount}("");      
        
        uint256 gasAfter = gasleft();

        // --- 4. Assertions ---
        require(success, "Fallback execution failed");

        uint256 gasUsed = gasBefore - gasAfter;
        
        // Check: Verify Gas usage exceeds stipend (2300)
        // Since the fallback writes to storage (SSTORE), it will significantly exceed 2300 gas.
        vm.assertTrue(gasUsed >= 2300, "Gas used does not exceed 2300");
    }
}
