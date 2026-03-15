// Generation Time: 15,75s
// Input Tokens: 1647
// Output Tokens: 278
// Reasoning Tokens: 2108


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {
    QuestGame questGame;

    event QuestAttempted(address indexed player, bool success, uint256 generatedNumber);

    function setUp() public {
        vm.deal(address(this), 10 ether);
        questGame = new QuestGame{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= 1 hours);
        vm.assume(blockNumber > 0);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    blockTimestamp,
                    blockNumber,
                    address(this)
                )
            )
        );
        uint256 expected = seed % 100;

        vm.expectEmit(true, true, true, true, address(questGame));
        emit QuestAttempted(address(this), true, expected);

        questGame.attemptQuest{value: questGame.ENTRY_FEE()}(expected);
    }
}
