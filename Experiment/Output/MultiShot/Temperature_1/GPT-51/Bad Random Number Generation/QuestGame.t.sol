// Generation Time: 24,58s
// Input Tokens: 1959
// Output Tokens: 395
// Reasoning Tokens: 2320


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {
    QuestGame public quest;

    function setUp() public {
        vm.deal(address(this), 100 ether);
        quest = new QuestGame{value: 10 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockTimestamp >= quest.COOLDOWN());
        vm.assume(blockNumber > block.number);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 expectedSeed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.number,
                    address(this)
                )
            )
        );
        uint256 expectedGenerated = expectedSeed % 100;

        (uint256 expBefore, uint256 winsBefore) = quest.getPlayerStats(address(this));
        uint256 balanceBefore = address(this).balance;

        quest.attemptQuest{value: quest.ENTRY_FEE()}(expectedGenerated);

        (uint256 expAfter, uint256 winsAfter) = quest.getPlayerStats(address(this));
        uint256 balanceAfter = address(this).balance;

        assertEq(expAfter, expBefore + 100, "Experience should increase by 100 on predicted win");
        assertEq(winsAfter, winsBefore + 1, "Wins should increase by 1 on predicted win");

        uint256 expectedNetGain = quest.REWARD() - quest.ENTRY_FEE();
        assertEq(balanceAfter, balanceBefore + expectedNetGain, "Balance net gain should equal reward minus entry fee");
    }
}
