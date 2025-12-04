
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {
    QuestGame public questGame;

    function setUp() public {
        vm.deal(address(this), 100 ether);
        questGame = new QuestGame{value: 10 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(type(uint256).max - blockNumber >= blockTimestamp);

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
        uint256 expectedRandom = seed % 100;

        vm.deal(address(this), address(this).balance + QuestGame.ENTRY_FEE());
        questGame.attemptQuest{value: QuestGame.ENTRY_FEE()}(expectedRandom);

        (uint256 exp, uint256 wins) = questGame.getPlayerStats(address(this));
        assertEq(wins, 1, "Wins should be 1 when guessing predictable random number");
        assertEq(exp, 100, "Experience should increase when guessing predictable random number");
    }
}
