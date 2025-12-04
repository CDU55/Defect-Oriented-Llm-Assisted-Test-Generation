
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
        assertTrue(success, "Call should succeed with unlimited gas");
        
        // Verify Gas usage exceeds the 2300 gas stipend
        // The complex fallback performs multiple storage writes and emits an event
        assertTrue(gasUsed > 2300, "Gas used should exceed 2300 gas stipend");
        
        // Additional verification: Demonstrate that transfer() would fail
        // due to the complex receive() function exceeding 2300 gas
        address sender2 = makeAddr("sender2");
        vm.deal(sender2, amount * 2);
        
        // Create a contract that uses transfer() to send Ether
        TransferSender transferContract = new TransferSender();
        vm.deal(address(transferContract), amount);
        
        // This should fail because transfer() only forwards 2300 gas
        // and the receive() function needs more
        vm.expectRevert();
        transferContract.sendViaTransfer(payable(address(_contractUnderTest)), amount);
    }
    
    function test_highlightReceiveFunctionIsComplex() public {
        // This test specifically demonstrates that the receive() function
        // contains operations that exceed the 2300 gas stipend
        
        uint256 amount = 1 ether;
        
        // Create sender with funds
        address sender = makeAddr("complexSender");
        vm.deal(sender, amount * 2);
        
        // Measure exact gas used by the receive function
        vm.prank(sender);
        uint256 gasStart = gasleft();
        (bool success, ) = address(_contractUnderTest).call{value: amount}("");
        uint256 gasEnd = gasleft();
        
        assertTrue(success, "Call with unlimited gas should succeed");
        
        uint256 totalGasUsed = gasStart - gasEnd;
        
        // The receive() function performs:
        // - Reading _state.isActive (SLOAD ~2100 gas for cold, ~100 for warm)
        // - Writing _state.lastInteractor (SSTORE ~20000 gas for new value)
        // - Reading and writing _state.interactionCount (SLOAD + SSTORE)
        // - Reading and writing interactions mapping (SLOAD + SSTORE)
        // - Emitting FundsReceived event (LOG ~375 + 375*topics + 8*data)
        
        // Assert that gas used significantly exceeds 2300
        assertTrue(totalGasUsed > 2300, "Receive function uses more than 2300 gas");
        
        // Verify the state was actually modified (proving the expensive operations occurred)
        assertEq(_contractUnderTest.interactions(sender), 1, "Interaction should be recorded");
    }
}

// Helper contract to test transfer() behavior
contract TransferSender {
    function sendViaTransfer(address payable recipient, uint256 amount) external {
        // transfer() only forwards 2300 gas
        recipient.transfer(amount);
    }
    
    function sendViaSend(address payable recipient, uint256 amount) external returns (bool) {
        // send() only forwards 2300 gas
        return recipient.send(amount);
    }
}
