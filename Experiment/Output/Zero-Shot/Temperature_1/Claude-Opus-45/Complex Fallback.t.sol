
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Crowdfund} from "../src/Crowdfund.sol";

contract TestComplexFallbackCrowdfund is Test {

    Crowdfund private _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Crowdfund();
    }

    function test_highlightGasNeededIsOver2300(uint256 amount) public {
        
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(amount > 0.01 ether && amount < type(uint128).max);

        // --- 2. State Configuration ---
        
        // A. Create and Fund a dedicated Sender address
        address sender = makeAddr("sender");
        vm.deal(sender, amount * 2);

        // B. Fund the Test Contract (Safety Net)
        vm.deal(address(this), amount * 2);

        // --- 3. Measure Gas Consumption ---
        
        vm.prank(sender);
        uint256 gasBefore = gasleft();
        
        // Trigger the receive function by sending Ether.
        // The receive() function performs multiple SSTORE operations:
        // 1. _state.lastInteractor = interactor (SSTORE - cold write)
        // 2. _state.interactionCount++ (SSTORE - read + write)
        // 3. interactions[interactor]++ (SSTORE - cold mapping write)
        // 4. emit FundsReceived (LOG operation)
        // These operations far exceed the 2300 gas stipend provided by .transfer() or .send()
        (bool success, ) = address(_contractUnderTest).call{value: amount}("");      
        
        uint256 gasAfter = gasleft();

        // --- 4. Assertions ---
        uint256 gasUsed = gasBefore - gasAfter;
        
        // Verify the call succeeded (since we used .call{} which forwards all gas)
        assertTrue(success, "Call should succeed with sufficient gas");
        
        // Verify Gas usage exceeds the 2300 stipend
        // This proves that using .transfer() or .send() would fail
        assertTrue(gasUsed > 2300, "Gas used does not exceed 2300");
    }

    function test_highlightTransferWouldFail(uint256 amount) public {
        // --- 1. Constraints & Pitfall Avoidance ---
        vm.assume(amount > 0.01 ether && amount < type(uint128).max);

        // --- 2. State Configuration ---
        address sender = makeAddr("sender");
        vm.deal(sender, amount * 2);

        // --- 3. Attempt to send with limited gas (simulating transfer/send) ---
        vm.prank(sender);
        
        // Using a low gas limit similar to what .transfer() provides (2300 gas)
        // This should fail because the receive() function is too complex
        (bool success, ) = address(_contractUnderTest).call{value: amount, gas: 2300}("");
        
        // --- 4. Assertions ---
        // The call should fail due to out of gas because:
        // - Writing to _state.lastInteractor (cold SSTORE ~20000 gas)
        // - Incrementing _state.interactionCount (SSTORE ~5000 gas)
        // - Incrementing interactions[sender] mapping (cold SSTORE ~20000 gas)
        // - Emitting FundsReceived event (LOG2 ~375+ gas)
        // Total exceeds 2300 gas significantly
        assertFalse(success, "Transfer with 2300 gas stipend should fail due to complex receive()");
    }

    function test_highlightGasConsumptionDetails() public {
        // Fixed amount for detailed gas analysis
        uint256 amount = 1 ether;
        
        address sender = makeAddr("sender");
        vm.deal(sender, amount * 2);

        vm.prank(sender);
        uint256 gasBefore = gasleft();
        
        (bool success, ) = address(_contractUnderTest).call{value: amount}("");
        
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;

        assertTrue(success, "Call should succeed");
        
        // The receive function performs:
        // 1. SLOAD for _state.isActive check
        // 2. SSTORE for _state.lastInteractor (cold slot ~20000 gas)
        // 3. SLOAD + SSTORE for _state.interactionCount++ 
        // 4. SLOAD + SSTORE for interactions[msg.sender]++ (cold mapping ~20000 gas)
        // 5. LOG2 for FundsReceived event
        // This easily exceeds 2300 gas
        
        assertTrue(gasUsed > 2300, "Gas consumption proves complex fallback vulnerability");
        
        // Log the actual gas used for visibility
        emit log_named_uint("Actual gas used by receive()", gasUsed);
        emit log_named_uint("Gas stipend for transfer/send", 2300);
        emit log_named_uint("Gas exceeding stipend", gasUsed - 2300);
    }
}
