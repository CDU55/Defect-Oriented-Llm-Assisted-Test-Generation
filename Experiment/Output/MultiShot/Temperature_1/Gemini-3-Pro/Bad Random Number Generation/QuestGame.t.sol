// Generation Time: 38,40s
// Input Tokens: 2495
// Output Tokens: 703
// Reasoning Tokens: 2835


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
        vm.deal(address(_contractUnderTest), 10 ether);

        // ───────────────────────────────────────────────────────── [/Setup]
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // ─────────────────────────────────────────────────────────────────────
        // [Setup] Constrain the inferred symbolic variables and fix the
        // environmental state using Forge cheatcodes (vm.warp, vm.roll, etc.)
        // to specific fuzzed or symbolic values.
        // ─────────────────────────────────────────────────────────────────────

        vm.assume(blockTimestamp >= 1 hours); // Minimum time to pass cooldown check
        vm.assume(blockNumber > 0);

        vm.deal(address(this), 1 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // ───────────────────────────────────────────────────────── [/Setup]

        // ─────────────────────────────────────────────────────────────────────
        // [Action] Instantiate mirroring logic to pre-calculate the expected
        // result using the same observable block data.
        // ─────────────────────────────────────────────────────────────────────
        
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

        _contractUnderTest.attemptQuest{value: 0.1 ether}(expectedRandom);

        // ─────────────────────────────────────────────────────────── [/Action]

        // ─────────────────────────────────────────────────────────────────────
        // [Assertion] Assert that the contract's output matches the
        // pre-calculated value.
        // ─────────────────────────────────────────────────────────────────────

        (, uint256 wins) = _contractUnderTest.getPlayerStats(address(this));
        assertEq(wins, 1, "Randomness should be predictable given block state");

        // ──────────────────────────────────────────────────── [/Assertion]
    }
}
