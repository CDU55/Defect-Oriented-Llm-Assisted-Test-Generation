// Generation Time: 32,88s
// Input Tokens: 2094
// Output Tokens: 997
// Reasoning Tokens: 2772


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

    QuestGame questGame;

    // ─────────────────────────────────────────────────────────────── [/Setup]

    function setUp() public {
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Initialize the contract under test.
        // ─────────────────────────────────────────────────────────────────────

        questGame = new QuestGame();
        // Fund the contract so it can pay out rewards (REWARD is 0.2 ether)
        vm.deal(address(questGame), 10 ether);
        
        // ───────────────────────────────────────────────────────── [/Setup]
    }

    // Needed to receive the reward payment
    receive() external payable {}

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Constrain the inferred symbolic variables and fix the
        // environmental state using Forge cheatcodes
        // to specific fuzzed or symbolic values.
        // ─────────────────────────────────────────────────────────────────────

        // Constrain timestamp to be at least the cooldown period (1 hour) to ensure the first attempt passes
        // (Initial lastAttemptTime is 0, COOLDOWN is 1 hours)
        blockTimestamp = bound(blockTimestamp, 1 hours, type(uint64).max);
        blockNumber = bound(blockNumber, 1, type(uint64).max);
        
        // Fund the test contract to pay the entry fee (ENTRY_FEE is 0.1 ether)
        vm.deal(address(this), 1 ether);

        // Apply the inferred values using Cheatcodes
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // ───────────────────────────────────────────────────────── [/Setup]

        // ─────────────────────────────────────────────────────────────────────
        // [Correlation Check] Execute the target "random" function multiple
        // times within the same simulated block or across identical
        // environmental parameters to verify consistency.
        // ─────────────────────────────────────────────────────────────────────

        // ────────────────────────────────────────────── [/Correlation Check]

        // ─────────────────────────────────────────────────────────────────────
        // [Action] Instantiate mirroring logic to pre-calculate the expected
        // result using the same observable block data.
        // ─────────────────────────────────────────────────────────────────────
        
        // Replicate the vulnerable logic locally inside the test.
        // Since we control the block state, we can calculate the exact result the contract *should* produce.
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
        // pre-calculated value (actualResult == preCalculatedResult). If these
        // values match across multiple fuzzed environments, the randomness is
        // confirmed to be predictable and potentially manipulable by miners
        // or validators.
        // ─────────────────────────────────────────────────────────────────────

        // Prove that the contract's "random" value matches our calculated expectation.
        (, uint256 wins) = questGame.getPlayerStats(address(this));
        assertEq(wins, 1, "The predicted number should result in a win due to predictable randomness");

        // ──────────────────────────────────────────────────── [/Assertion]
    }
}
