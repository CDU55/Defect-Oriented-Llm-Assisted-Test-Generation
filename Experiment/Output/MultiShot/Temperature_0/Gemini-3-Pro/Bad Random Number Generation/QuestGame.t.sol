// Generation Time: 25,27s
// Input Tokens: 2495
// Output Tokens: 858
// Reasoning Tokens: 1959


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

    QuestGame public _contractUnderTest;

    // ─────────────────────────────────────────────────────────────── [/Setup]

    function setUp() public {
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Initialize the contract under test.
        // ─────────────────────────────────────────────────────────────────────

        _contractUnderTest = new QuestGame();
        
        // Fund the contract so it can pay out rewards
        vm.deal(address(_contractUnderTest), 10 ether);
        
        // Fund the test contract to pay entry fees
        vm.deal(address(this), 10 ether);

        // ───────────────────────────────────────────────────────── [/Setup]
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Constrain the inferred symbolic variables and fix the
        // environmental state using Forge cheatcodes (vm.warp, vm.roll, etc.)
        // to specific fuzzed or symbolic values.
        // ─────────────────────────────────────────────────────────────────────

        // Ensure timestamp is large enough to pass the cooldown check (lastAttemptTime is initially 0)
        // Requirement: block.timestamp >= 0 + 1 hours
        vm.assume(blockTimestamp >= 1 hours);
        vm.assume(blockNumber > 0);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // ───────────────────────────────────────────────────────── [/Setup]

        // ─────────────────────────────────────────────────────────────────────
        // [Action] Instantiate mirroring logic to pre-calculate the expected
        // result using the same observable block data.
        // ─────────────────────────────────────────────────────────────────────
        
        // Replicate the vulnerable logic locally inside the test.
        // We use address(this) because this test contract is the msg.sender calling the target.
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

        // ─────────────────────────────────────────────────────────── [/Action]

        // ─────────────────────────────────────────────────────────────────────
        // [Assertion] Assert that the contract's output matches the
        // pre-calculated value.
        // ─────────────────────────────────────────────────────────────────────

        // If our prediction was correct, we should have won.
        // Check player stats to verify the win count incremented.
        (, uint256 wins) = _contractUnderTest.getPlayerStats(address(this));
        
        assertEq(wins, 1, "Randomness should be predictable given block state");

        // ──────────────────────────────────────────────────── [/Assertion]
    }

    // Allow the contract to receive the reward ETH
    receive() external payable {}
}
