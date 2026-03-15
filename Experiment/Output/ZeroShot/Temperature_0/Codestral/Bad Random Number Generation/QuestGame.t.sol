// Generation Time: 1,87s
// Input Tokens: 2636
// Output Tokens: 331
// Reasoning Tokens: 


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public game;

    function setUp() public {
        vm.deal(address(this), 1 ether);
        game = new QuestGame{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.startPrank(address(this));

        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    blockTimestamp,
                    blockNumber,
                    address(this)
                )
            )
        );

        uint256 preCalculatedNumber = seed % 100;

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 actualNumber;
        emit log_named_uint("Pre-calculated number", preCalculatedNumber);

        vm.expectEmit(true, true, true, true);
        game.QuestAttempted(address(this), true, preCalculatedNumber);
        game.attemptQuest{value: 0.1 ether}(preCalculatedNumber);

        actualNumber = seed % 100;
        emit log_named_uint("Actual number", actualNumber);

        assertEq(actualNumber, preCalculatedNumber, "Random number generation is predictable");
    }
}
