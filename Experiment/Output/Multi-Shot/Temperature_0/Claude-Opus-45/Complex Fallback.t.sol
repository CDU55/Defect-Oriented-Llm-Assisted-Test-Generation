
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
        
        // Create and Fund a dedicated Sender address
        address sender = makeAddr("sender");
        vm.deal(sender, amount * 2);

        // Fund the Test Contract (Safety Net)
        vm.deal(address(this), amount * 2);

        // --- 3. Measure Gas Consumption ---
        
        vm.prank(sender);
        uint256 gasBefore = gasleft();
        
        // Trigger the receive() function by sending Ether
        // The receive() function performs multiple SSTORE operations:
        // 1. _state.lastInteractor = interactor (SSTORE - cold slot write)
        // 2. _state.interactionCount++ (SSTORE - cold slot read + write)
        // 3. interactions[interactor]++ (SSTORE - cold mapping slot write)
        // 4. emit FundsReceived (LOG operation)
        // These operations far exceed the 2300 gas stipend
        (bool success, ) = address(_contractUnderTest).call{value: amount}("");      
        
        uint256 gasAfter = gasleft();

        // --- 4. Assertions ---
        uint256 gasUsed = gasBefore - gasAfter;
        
        // Verify the call succeeded (with full gas available via .call)
        assertTrue(success, "Call should succeed with full gas");
        
        // Verify Gas usage exceeds the 2300 stipend
        // The receive() function performs:
        // - Conditional check on _state.isActive (SLOAD ~2100 gas for cold)
        // - _state.lastInteractor write (SSTORE ~20000 gas for cold slot)
        // - _state.interactionCount increment (SLOAD + SSTORE)
        // - interactions[interactor] increment (SSTORE ~20000 gas for cold mapping slot)
        // - Event emission (LOG2 ~375 + 8*data_size)
        assertTrue(gasUsed > 2300, "Gas used should exceed 2300 stipend");
        
        // Additional assertion: Demonstrate that transfer() or send() would fail
        // because they only forward 2300 gas
        address sender2 = makeAddr("sender2");
        vm.deal(sender2, amount * 2);
        
        vm.prank(sender2);
        // Using send() which caps gas at 2300 - this should fail
        bool sendSuccess = payable(address(_contractUnderTest)).send(amount);
        
        // The send should fail because receive() needs more than 2300 gas
        assertFalse(sendSuccess, "send() should fail due to gas limit of 2300");
    }
    
    function test_highlightTransferFails() public {
        uint256 amount = 1 ether;
        
        // Create a contract that will try to use transfer()
        TransferCaller caller = new TransferCaller();
        vm.deal(address(caller), amount * 2);
        
        // This should revert because transfer() only forwards 2300 gas
        // and the Crowdfund receive() function needs more
        vm.expectRevert();
        caller.tryTransfer{value: amount}(payable(address(_contractUnderTest)));
    }
}

// Helper contract to test transfer() behavior
contract TransferCaller {
    function tryTransfer(address payable target) external payable {
        // transfer() only forwards 2300 gas stipend
        target.transfer(msg.value);
    }
    
    receive() external payable {}
}
