
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
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber > 0);
        vm.assume(blockTimestamp < type(uint128).max);
        vm.assume(blockNumber < type(uint128).max);

        // --- 2. State Configuration ---
        vm.deal(address(this), 100 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable Deck.deal logic locally
        // The contract uses: keccak256(abi.encodePacked(blockhash(block.number), player, cardNumber, block.timestamp)) % 52
        
        address player = address(this);
        
        // Predict all three cards that will be dealt
        uint8 expectedPlayerCard0 = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber), player, uint8(0), blockTimestamp))) % 52);
        uint8 expectedHouseCard0 = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber), player, uint8(1), blockTimestamp))) % 52);
        uint8 expectedPlayerCard1 = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber), player, uint8(2), blockTimestamp))) % 52);

        // Execute the deal function
        _contractUnderTest.deal{value: 0.05 ether}();

        // Get the actual cards dealt
        uint8 actualPlayerCard0 = _contractUnderTest.getPlayerCard(0);
        uint8 actualPlayerCard1 = _contractUnderTest.getPlayerCard(1);
        uint8 actualHouseCard0 = _contractUnderTest.getHouseCard(0);

        // Assert that we could predict the random values
        assertEq(actualPlayerCard0, expectedPlayerCard0, "Player card 0 should be predictable given block state");
        assertEq(actualHouseCard0, expectedHouseCard0, "House card 0 should be predictable given block state");
        assertEq(actualPlayerCard1, expectedPlayerCard1, "Player card 1 should be predictable given block state");
    }

    receive() external payable {}
}
