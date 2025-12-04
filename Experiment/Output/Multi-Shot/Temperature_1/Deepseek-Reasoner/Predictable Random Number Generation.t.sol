
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {
    QuestGame public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 100 ether);
        _contractUnderTest = new QuestGame{value: 10 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(type(uint256).max - blockNumber >= blockTimestamp);

        address user = address(0x123);
        vm.deal(user, 100 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 expectedSeed = uint256(
            keccak256(
                abi.encodePacked(
                    blockTimestamp, 
                    blockNumber, 
                    user
                )
            )
        );
        uint256 expectedGeneratedNumber = expectedSeed % 100;

        vm.prank(user);
        _contractUnderTest.attemptQuest{value: 0.1 ether}(expectedGeneratedNumber);

        (uint256 exp, uint256 wins) = _contractUnderTest.getPlayerStats(user);
        assertEq(wins, 1, "Player should have won with predictable random number");
    }
}
