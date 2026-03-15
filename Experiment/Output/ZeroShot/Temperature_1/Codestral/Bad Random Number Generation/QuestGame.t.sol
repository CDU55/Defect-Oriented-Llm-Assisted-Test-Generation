// Generation Time: 1,40s
// Input Tokens: 2636
// Output Tokens: 279
// Reasoning Tokens: 


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
        vm.assume(blockTimestamp > 0);
        vm.assume(blockNumber > 0);

        vm.startPrank(address(this));
        vm.deal(address(this), 0.1 ether);

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

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        questGame.attemptQuest{value: 0.1 ether}(expectedNumber);

        vm.stopPrank();
    }
}
