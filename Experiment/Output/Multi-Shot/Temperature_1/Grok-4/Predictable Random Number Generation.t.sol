
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public questGame;

    function setUp() public {
        vm.deal(address(this), 1 ether);
        questGame = new QuestGame{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(blockTimestamp >= 1 hours);
        
        // --- 2. State Configuration ---
        
        vm.deal(address(this), 0.1 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    blockTimestamp, 
                    blockNumber, 
                    address(this) 
                )
            )
        );

        uint256 expectedNumber = seed % 100;
        
        questGame.attemptQuest{value: 0.1 ether}(expectedNumber);

        (uint256 exp, uint256 wins) = questGame.getPlayerStats(address(this));
        assertEq(exp, 100, "Should have gained experience");
        assertEq(wins, 1, "Should have won");
    }
}
