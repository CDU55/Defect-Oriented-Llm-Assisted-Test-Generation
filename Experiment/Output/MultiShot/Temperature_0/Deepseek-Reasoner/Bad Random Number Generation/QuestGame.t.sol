// Generation Time: 86,83s
// Input Tokens: 2484
// Output Tokens: 548
// Reasoning Tokens: 2956


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

        vm.deal(address(this), 100 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 firstGuess = 0;
        uint256 secondGuess = 0;

        vm.deal(address(1), 100 ether);
        vm.startPrank(address(1));

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);
        _contractUnderTest.attemptQuest{value: 0.1 ether}(firstGuess);
        vm.stopPrank();

        vm.deal(address(2), 100 ether);
        vm.startPrank(address(2));

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);
        _contractUnderTest.attemptQuest{value: 0.1 ether}(secondGuess);
        vm.stopPrank();

        vm.recordLogs();

        vm.startPrank(address(1));
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);
        _contractUnderTest.attemptQuest{value: 0.1 ether}(0);
        vm.stopPrank();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        
        require(entries.length > 0, "No event emitted");
        
        (address player, bool success, uint256 generatedNumber) = abi.decode(
            entries[0].data,
            (address, bool, uint256)
        );

        uint256 expectedSeed = uint256(
            keccak256(
                abi.encodePacked(
                    blockTimestamp,
                    blockNumber,
                    address(1)
                )
            )
        );
        uint256 expectedRandom = expectedSeed % 100;

        assertEq(generatedNumber, expectedRandom, "Randomness should be predictable given block state");
    }
}
