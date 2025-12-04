
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
        // 1. Updates _state.lastInteractor (SSTORE)
        // 2. Increments _state.interactionCount (SLOAD + SSTORE)
        // 3. Increments interactions[interactor] mapping (SLOAD + SSTORE)
        // 4. Emits FundsReceived event (LOG)
        // These operations far exceed the 2300 gas stipend
        (bool success, ) = address(_contractUnderTest).call{value: amount}("");
        
        uint256 gasAfter = gasleft();

        // --- 4. Assertions ---
        uint256 gasUsed = gasBefore - gasAfter;
        
        // Verify the call succeeded (it uses .call which forwards all gas)
        assertTrue(success, "Call should succeed with sufficient gas");
        
        // Verify Gas usage exceeds the 2300 stipend
        // The receive() function performs multiple storage writes and emits an event
        // which costs significantly more than 2300 gas
        assertTrue(gasUsed > 2300, "Gas used should exceed 2300 gas stipend");
        
        // Additional assertion: Verify that using transfer() or send() would fail
        // because they only forward 2300 gas
        address sender2 = makeAddr("sender2");
        vm.deal(sender2, amount * 2);
        
        vm.prank(sender2);
        // send() only forwards 2300 gas - this should fail due to complex fallback
        bool sendSuccess = payable(address(_contractUnderTest)).send(amount);
        
        // The send should fail because receive() requires more than 2300 gas
        assertFalse(sendSuccess, "send() should fail due to gas limit of 2300");
    }
    
    function test_highlightReceiveTooExpensiveForTransfer() public {
        // This test specifically proves the vulnerability by showing
        // that transfer() fails due to the complex receive() function
        
        uint256 amount = 1 ether;
        
        // Create a contract that tries to send Ether via transfer()
        TransferSender transferSender = new TransferSender();
        vm.deal(address(transferSender), amount * 2);
        
        // Attempt to send via transfer() - should fail due to 2300 gas limit
        bool success = transferSender.sendViaTransfer(payable(address(_contractUnderTest)), amount);
        
        // transfer() should fail because receive() uses more than 2300 gas
        assertFalse(success, "transfer() should fail due to complex receive()");
    }
}

// Helper contract to test transfer() behavior
contract TransferSender {
    function sendViaTransfer(address payable recipient, uint256 amount) external returns (bool) {
        try this.doTransfer(recipient, amount) {
            return true;
        } catch {
            return false;
        }
    }
    
    function doTransfer(address payable recipient, uint256 amount) external {
        recipient.transfer(amount);
    }
    
    receive() external payable {}
}
