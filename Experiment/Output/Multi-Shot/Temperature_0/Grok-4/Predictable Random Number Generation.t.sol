
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public questGame;

    function setUp() public {
        vm.deal(address(this), 100 ether);
        questGame = new QuestGame{value: 10 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(blockTimestamp >= 1 hours);

        // --- 2. State Configuration ---
        
        // MANIPULATE BLOCK ENVIRONMENT
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // PREDICT THE OUTCOME
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    blockTimestamp, 
                    blockNumber, 
                    address(this) 
                )
            )
        );

        uint256 expectedNumber = seed % 100;
        
        // EXECUTE
        uint256 guess = (expectedNumber + 1) % 100;
        
        vm.recordLogs();
        questGame.attemptQuest{value: 0.1 ether}(guess);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);
        
        (bool success, uint256 actualNumber) = abi.decode(entries[0].data, (bool, uint256));
        
        // ASSERT PREDICTABILITY
        assertEq(actualNumber, expectedNumber, "Randomness should be predictable given block state");
    }
}
