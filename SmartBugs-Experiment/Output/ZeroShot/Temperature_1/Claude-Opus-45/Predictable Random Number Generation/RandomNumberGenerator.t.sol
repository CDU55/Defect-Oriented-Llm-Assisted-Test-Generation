
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {

    RandomNumberGenerator private rng;

    function setUp() public {
        rng = new RandomNumberGenerator();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        // Constrain blockTimestamp to avoid zero and keep it reasonable
        vm.assume(blockTimestamp > 0);
        vm.assume(blockTimestamp < type(uint128).max);
        
        // Constrain blockNumber to avoid division by zero and ensure valid blockhash range
        vm.assume(blockNumber > 256);
        vm.assume(blockNumber < type(uint128).max);
        
        // salt % 5 must not be zero to avoid division by zero in the contract
        vm.assume(blockTimestamp % 5 != 0);
        
        // Ensure seed calculation doesn't overflow and produces valid blockhash index
        uint256 salt = blockTimestamp;
        uint256 y = salt * blockNumber / (salt % 5);
        uint256 seed = blockNumber / 3 + (salt % 300) + y;
        
        // blockhash only works for recent 256 blocks, seed must be < blockNumber and >= blockNumber - 256
        vm.assume(seed < blockNumber);
        vm.assume(seed >= blockNumber - 256);
        
        // Avoid overflow in salt * 100 and salt * blockNumber
        vm.assume(salt < type(uint256).max / 100);
        vm.assume(salt < type(uint256).max / blockNumber);

        uint256 max = 100;
        
        // Ensure x is not zero to avoid division by zero
        uint256 x = salt * 100 / max;
        vm.assume(x > 0);

        // --- 2. State Configuration ---
        
        // Manipulate block environment
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Predict the outcome by replicating the vulnerable logic
        // The salt is set to block.timestamp at deployment time
        // Since we deployed in setUp() before warping, we need to redeploy
        // to capture the new timestamp as salt
        
        // Redeploy after setting block state so salt captures our controlled timestamp
        rng = new RandomNumberGenerator();
        
        // Now replicate the exact calculation the contract performs
        uint256 predictedSalt = blockTimestamp; // salt = block.timestamp at deployment
        uint256 predictedX = predictedSalt * 100 / max;
        uint256 predictedY = predictedSalt * blockNumber / (predictedSalt % 5);
        uint256 predictedSeed = blockNumber / 3 + (predictedSalt % 300) + predictedY;
        uint256 predictedH = uint256(blockhash(predictedSeed));
        uint256 predictedResult = uint256((predictedH / predictedX)) % max + 1;
        
        // Execute the contract method
        uint256 actualResult = rng.random(max);

        // Assert predictability - the "random" value matches our calculated expectation
        assertEq(actualResult, predictedResult, "Random value should be predictable");
    }
}
