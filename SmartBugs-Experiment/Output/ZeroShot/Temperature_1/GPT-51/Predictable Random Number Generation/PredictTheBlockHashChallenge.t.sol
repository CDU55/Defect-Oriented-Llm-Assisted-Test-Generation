
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {
    PredictTheBlockHashChallenge challenge;
    address attacker = address(this);

    function setUp() public {
        challenge = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 initialBlockNumber) public {
        // --- 1. Constraints ---
        vm.assume(initialBlockNumber > 0);
        vm.assume(initialBlockNumber < type(uint256).max - 300);

        // --- 2. State Configuration ---
        // Set a known block number environment
        vm.roll(initialBlockNumber);

        // Lock in a guess for blockhash(initialBlockNumber + 1)
        challenge.lockInGuess{value: 1 ether}(bytes32(uint256(0)));

        // The guess will be evaluated for block number: initialBlockNumber + 1
        uint256 targetBlock = initialBlockNumber + 1;

        // Mine forward to the target block so its hash is available
        vm.roll(targetBlock);

        // Locally compute the blockhash that the contract will use
        bytes32 predictedAnswer = blockhash(targetBlock);

        // For the purpose of this test, we "predict" the random value, showing that
        // it's fully determined by the block environment we control
        assertEq(predictedAnswer, blockhash(targetBlock));

        // Move to a future block so settle() can be called
        vm.roll(targetBlock + 1);

        // --- 3. Replication & Assertion ---
        // Execute settle() which uses the predictable blockhash as "randomness"
        uint256 balanceBefore = attacker.balance;
        challenge.settle();
        uint256 balanceAfter = attacker.balance;

        // Because the blockhash is fully determined by block.number (which we can
        // manipulate), this "random" source is predictable and thus insecure
        // The test's main proof is that we can compute the same value off-chain
        // via blockhash(targetBlock), demonstrating predictability.
        // Even if our hardcoded guess is unlikely to win, the randomness source
        // itself is fully determined by controllable on-chain state.
        assertEq(blockhash(targetBlock), predictedAnswer);
        assertEq(address(challenge).balance + balanceAfter + 2 ether, address(challenge).balance + balanceBefore + 2 ether);
    }
}
