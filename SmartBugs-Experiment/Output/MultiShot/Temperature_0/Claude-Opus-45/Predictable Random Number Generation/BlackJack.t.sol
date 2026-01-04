
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack, Deck} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {

    BlackJack public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new BlackJack();
        vm.deal(address(_contractUnderTest), 100 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= 1);
        vm.assume(blockNumber <= type(uint256).max - 1000);
        vm.assume(blockTimestamp <= type(uint256).max - 1000);

        // --- 2. State Configuration ---
        vm.deal(address(this), 100 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable Deck.deal logic locally
        // The contract uses: keccak256(abi.encodePacked(blockhash(block.number), player, cardNumber, block.timestamp)) % 52
        
        address player = address(this);
        
        // Predict the cards that will be dealt
        uint8 expectedPlayerCard0 = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber), player, uint8(0), blockTimestamp))) % 52);
        uint8 expectedHouseCard0 = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber), player, uint8(1), blockTimestamp))) % 52);
        uint8 expectedPlayerCard1 = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber), player, uint8(2), blockTimestamp))) % 52);

        // Execute the deal function
        _contractUnderTest.deal{value: 0.05 ether}();

        // Get the actual cards dealt
        uint8 actualPlayerCard0 = _contractUnderTest.getPlayerCard(0);
        uint8 actualPlayerCard1 = _contractUnderTest.getPlayerCard(1);
        uint8 actualHouseCard0 = _contractUnderTest.getHouseCard(0);

        // Assert that we can predict the random values
        assertEq(actualPlayerCard0, expectedPlayerCard0, "Player card 0 should be predictable given block state");
        assertEq(actualHouseCard0, expectedHouseCard0, "House card 0 should be predictable given block state");
        assertEq(actualPlayerCard1, expectedPlayerCard1, "Player card 1 should be predictable given block state");
    }

    function getCardValue(uint8 card, bool isBigAce) internal pure returns (uint8) {
        uint8 value = card / 4;
        if (value == 0 || value == 11 || value == 12) {
            return 10;
        }
        if (value == 1 && isBigAce) {
            return 11;
        }
        return value;
    }

    receive() external payable {}
}
