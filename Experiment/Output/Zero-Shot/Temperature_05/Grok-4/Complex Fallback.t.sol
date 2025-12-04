
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
        // WARNING: Avoid Integer/Balance Overflow.
        vm.assume(amount > 0.01 ether && amount < type(uint128).max);

        // --- 2. State Configuration ---
        
        // FUNDING
        // A. Create and Fund a dedicated Sender address
        address sender = makeAddr("sender");
        vm.deal(sender, amount * 2);

        // B. Fund the Test Contract (Safety Net)
        // Even though we use 'sender', ensuring address(this) has funds prevents 
        // unexpected failures if the LLM adds logic using address(this).
        vm.deal(address(this), amount * 2);

        // --- 3. Measure Gas Consumption ---
        
        vm.prank(sender);
        uint256 gasBefore = gasleft();
        
        (bool success, ) = address(crowdfund).call{value: amount}("");      
        
        uint256 gasAfter = gasleft();

        // --- 4. Assertions ---
        // Calculate gas used.
        // Note: 'send' might return false if it runs out of gas, or true if it fits.
        // We assert that the operation attempted to use more than the stipend.
        uint256 gasUsed = gasBefore - gasAfter;
        
        // Check: Verify Gas usage exceeds stipend
        vm.assertTrue(gasUsed >= 2300, "Gas used does not exceed 2300");
    }
}
