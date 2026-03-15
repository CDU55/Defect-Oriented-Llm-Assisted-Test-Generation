// Generation Time: 54,14s
// Input Tokens: 2484
// Output Tokens: 332
// Reasoning Tokens: 1465


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {
    QuestGame public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new QuestGame();
        vm.deal(address(_contractUnderTest), 100 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(type(uint256).max - blockNumber >= blockTimestamp);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 expectedRandom = uint256(
            keccak256(
                abi.encodePacked(
                    blockTimestamp,
                    blockNumber,
                    address(this)
                )
            )
        ) % 100;

        vm.deal(address(this), 1 ether);
        
        uint256 initialWins = _contractUnderTest.players(address(this)).wins;
        
        _contractUnderTest.attemptQuest{value: 0.1 ether}(expectedRandom);
        
        uint256 finalWins = _contractUnderTest.players(address(this)).wins;
        
        assertEq(finalWins, initialWins + 1, "Randomness should be predictable given block state");
    }
}
