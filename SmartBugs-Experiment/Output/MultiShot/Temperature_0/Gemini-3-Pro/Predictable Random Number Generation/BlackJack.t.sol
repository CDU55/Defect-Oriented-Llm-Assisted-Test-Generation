
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {

    BlackJack public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new BlackJack();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockTimestamp > 0);
        vm.assume(blockNumber > 0);

        // --- 2. State Configuration ---
        
        vm.deal(address(this), 100 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Replicate the logic used in Deck.deal
        // The contract calculates randomness based on blockhash(block.number), msg.sender, cardNumber, and block.timestamp.
        // Note: blockhash(block.number) evaluates to 0 in EVM.
        
        bytes32 bHash = blockhash(block.number);
        address player = address(this);
        uint8 cardNumber = 0; // The first card dealt to the player has index 0
        
        uint8 expectedCard = uint8(uint256(keccak256(abi.encodePacked(bHash, player, cardNumber, blockTimestamp))) % 52);
        
        // Execute
        _contractUnderTest.deal{value: 0.05 ether}();

        // Retrieve the actual card dealt
        uint8 actualCard = _contractUnderTest.getPlayerCard(0);

        // Assert
        assertEq(actualCard, expectedCard, "Randomness should be predictable given block state");
    }

    receive() external payable {}
}
