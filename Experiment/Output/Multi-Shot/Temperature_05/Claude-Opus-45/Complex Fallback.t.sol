
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
        
        // Verify the call succeeded (it will succeed with .call but would fail with .transfer)
        assertTrue(success, "Call should succeed with sufficient gas");
        
        // Verify Gas usage exceeds the 2300 gas stipend
        // The receive() function performs:
        // - Conditional check on _state.isActive (SLOAD ~2100 gas for cold, 100 for warm)
        // - _state.lastInteractor = interactor (SSTORE ~20000 gas for new value)
        // - _state.interactionCount++ (SLOAD + SSTORE)
        // - interactions[interactor]++ (SLOAD + SSTORE for mapping)
        // - emit FundsReceived (LOG2 ~375 + 8*data_size)
        assertTrue(gasUsed > 2300, "Gas used should exceed 2300 gas stipend");
        
        // Additional assertion: Demonstrate that transfer() would fail
        // by showing the gas requirement is significantly higher than 2300
        assertTrue(gasUsed > 10000, "Gas used should be significantly higher than stipend due to multiple SSTOREs");
    }

    function test_transferWouldFailDueToComplexReceive() public {
        // This test demonstrates that using transfer() or send() would fail
        // because the receive() function is too complex
        
        address sender = makeAddr("sender");
        uint256 amount = 1 ether;
        vm.deal(sender, amount * 2);

        // Create a contract that uses transfer() to send funds
        TransferSender transferSender = new TransferSender();
        vm.deal(address(transferSender), amount * 2);

        // Attempt to send via transfer() - this should fail due to gas limit
        vm.expectRevert();
        transferSender.sendViaTransfer(payable(address(_contractUnderTest)), amount);
    }

    function test_sendWouldFailDueToComplexReceive() public {
        // This test demonstrates that send() returns false due to complex receive()
        
        address sender = makeAddr("sender");
        uint256 amount = 1 ether;
        vm.deal(sender, amount * 2);

        // Create a contract that uses send() to send funds
        SendSender sendSender = new SendSender();
        vm.deal(address(sendSender), amount * 2);

        // send() should return false due to out of gas
        bool success = sendSender.sendViaSend(payable(address(_contractUnderTest)), amount);
        assertFalse(success, "send() should fail due to complex receive() exceeding 2300 gas");
    }
}

// Helper contract to test transfer()
contract TransferSender {
    function sendViaTransfer(address payable recipient, uint256 amount) external {
        recipient.transfer(amount);
    }
}

// Helper contract to test send()
contract SendSender {
    function sendViaSend(address payable recipient, uint256 amount) external returns (bool) {
        return recipient.send(amount);
    }
}
