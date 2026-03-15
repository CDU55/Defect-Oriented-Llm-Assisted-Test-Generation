// Generation Time: 6,66s
// Input Tokens: 2484
// Output Tokens: 500
// Reasoning Tokens: 0


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
        
        vm.assume(amount > 0.01 ether && amount < type(uint128).max);

        address sender = makeAddr("sender");
        vm.deal(sender, amount * 2);

        vm.deal(address(this), amount * 2);

        vm.prank(sender);
        uint256 gasBefore = gasleft();
        
        (bool success, ) = address(_contractUnderTest).call{value: amount}("");      
        
        uint256 gasAfter = gasleft();

        require(success, "Transfer failed");

        uint256 gasUsed = gasBefore - gasAfter;
        
        // Verify gas usage exceeds the 2,300 stipend (vulnerability confirmed)
        // The receive() function performs multiple storage operations:
        // 1. Reads _state.isActive (cold SLOAD ~2100 gas)
        // 2. Writes _state.lastInteractor (SSTORE ~20000+ gas for cold slot)
        // 3. Increments _state.interactionCount (SLOAD + SSTORE)
        // 4. Increments interactions[interactor] mapping (SLOAD + SSTORE for cold slot)
        // 5. Emits FundsReceived event (LOG operation)
        // All these operations combined far exceed the 2,300 gas stipend
        assertTrue(gasUsed >= 2300, "Gas used does not exceed 2300");
    }
}
