
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Crowdfund} from "../src/Crowdfund.sol";

contract TestComplexFallbackCrowdfund is Test {
    
    Crowdfund public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Crowdfund();
    }

    function test_highlightGasNeededIsOver2300(uint256 amount) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(amount > 0.01 ether && amount < type(uint128).max);

        // --- 2. State Configuration ---
        
        address sender = makeAddr("sender");
        vm.deal(sender, amount * 2);

        vm.deal(address(this), amount * 2);

        // --- 3. Measure Gas Consumption ---
        
        vm.prank(sender);
        uint256 gasBefore = gasleft();
        
        // We use .call to forward all available gas and measure how much is actually consumed.
        // If we used .transfer or .send, it would revert immediately due to the 2300 gas cap.
        (bool success, ) = address(_contractUnderTest).call{value: amount}("");      
        
        uint256 gasAfter = gasleft();

        // Ensure the transaction succeeded to validate the cost of the happy path
        vm.assertTrue(success, "Transaction failed unexpectedly");

        // --- 4. Assertions ---
        uint256 gasUsed = gasBefore - gasAfter;
        
        // Check: Verify Gas usage exceeds stipend
        // The Crowdfund contract writes to storage in the receive() function, 
        // which inevitably costs more than the 2300 gas stipend provided by .transfer/.send.
        vm.assertTrue(gasUsed > 2300, "Gas used does not exceed 2300");
    }
}
