// Generation Time: 1,51s
// Input Tokens: 3026
// Output Tokens: 310
// Reasoning Tokens: 


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new QuestGame();
        vm.deal(address(_contractUnderTest), 1 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(type(uint256).max - blockNumber >= blockTimestamp);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 expectedSeed = uint256(keccak256(abi.encodePacked(blockTimestamp, blockNumber, address(this))));
        uint256 expectedRandom = expectedSeed % 100;

        vm.deal(address(this), 1 ether);
        _contractUnderTest.attemptQuest{value: 0.1 ether}(expectedRandom);

        (uint256 exp, ) = _contractUnderTest.getPlayerStats(address(this));
        assertEq(exp, 100, "Randomness should be predictable given block state");
    }
}
