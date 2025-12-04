
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {
    QuestGame public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new QuestGame{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(type(uint256).max - blockNumber >= blockTimestamp);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 expectedSeed = uint256(
            keccak256(
                abi.encodePacked(
                    blockTimestamp, 
                    blockNumber, 
                    address(this)
                )
            )
        );
        uint256 expectedGeneratedNumber = expectedSeed % 100;

        uint256 initialBalance = address(this).balance;
        vm.deal(address(this), initialBalance + 0.1 ether);

        _contractUnderTest.attemptQuest{value: 0.1 ether}(expectedGeneratedNumber);

        (uint256 exp, uint256 wins) = _contractUnderTest.getPlayerStats(address(this));
        assertEq(wins, 1, "Player should win when random number is predictable");
        assertEq(exp, 100, "Player should gain 100 experience when winning");
    }
}
