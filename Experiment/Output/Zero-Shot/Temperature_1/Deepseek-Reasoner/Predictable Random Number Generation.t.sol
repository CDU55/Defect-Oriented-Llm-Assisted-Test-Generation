
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {
    QuestGame public game;
    
    function setUp() public {
        game = new QuestGame{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= 1 hours);
        vm.assume(blockNumber > 0);
        vm.assume(blockTimestamp <= type(uint256).max - 1 hours);
        
        address player = address(0x1234);
        vm.deal(player, 1 ether);
        
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);
        
        uint256 expectedSeed = uint256(
            keccak256(
                abi.encodePacked(
                    blockTimestamp,
                    blockNumber,
                    player
                )
            )
        );
        uint256 expectedNumber = expectedSeed % 100;
        
        vm.prank(player);
        game.attemptQuest{value: 0.1 ether}(expectedNumber);
        
        (uint256 exp, uint256 wins) = game.getPlayerStats(player);
        assertEq(wins, 1);
        assertEq(exp, 100);
    }
}
