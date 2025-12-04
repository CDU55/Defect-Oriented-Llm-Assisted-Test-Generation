
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
        
        // The receive() function should succeed with call{} but would fail with transfer/send
        assertTrue(success, "Call should succeed with sufficient gas");
        
        // Verify Gas usage exceeds the 2300 stipend that transfer/send would provide
        assertTrue(gasUsed > 2300, "Gas used does not exceed 2300");
        
        // Additional verification: demonstrate that transfer/send would fail
        // due to the complex fallback operations
        address sender2 = makeAddr("sender2");
        vm.deal(sender2, amount * 2);
        
        // Create a contract that uses transfer to send funds
        TransferSender transferSender = new TransferSender();
        vm.deal(address(transferSender), amount * 2);
        
        // This should fail because transfer only provides 2300 gas
        // and the receive() function needs more
        bool transferSuccess = transferSender.sendViaTransfer(payable(address(_contractUnderTest)), amount);
        assertFalse(transferSuccess, "Transfer should fail due to gas limit");
    }
    
    function test_highlightReceiveFunctionExceedsGasStipend() public {
        uint256 amount = 1 ether;
        
        // Create a sender contract that uses transfer (2300 gas stipend)
        TransferSender transferSender = new TransferSender();
        vm.deal(address(transferSender), amount * 2);
        
        // Attempt to send via transfer - should fail due to complex receive()
        bool success = transferSender.sendViaTransfer(payable(address(_contractUnderTest)), amount);
        
        // Assert that transfer fails due to out of gas
        assertFalse(success, "Transfer should fail - receive() exceeds 2300 gas stipend");
        
        // Verify that call with unlimited gas succeeds
        vm.deal(address(this), amount * 2);
        (bool callSuccess, ) = address(_contractUnderTest).call{value: amount}("");
        assertTrue(callSuccess, "Call with unlimited gas should succeed");
    }
}

// Helper contract to test transfer behavior
contract TransferSender {
    function sendViaTransfer(address payable recipient, uint256 amount) external returns (bool) {
        // transfer() only forwards 2300 gas
        // We use a try-catch pattern since transfer reverts on failure
        try this.doTransfer(recipient, amount) {
            return true;
        } catch {
            return false;
        }
    }
    
    function doTransfer(address payable recipient, uint256 amount) external {
        require(msg.sender == address(this), "Only self");
        recipient.transfer(amount);
    }
    
    receive() external payable {}
}
