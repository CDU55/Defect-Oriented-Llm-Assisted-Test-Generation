
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
        // Constrain blockTimestamp to avoid edge cases
        vm.assume(blockTimestamp > 0);
        vm.assume(blockTimestamp < type(uint128).max);
        
        // Constrain blockNumber to ensure valid blockhash and avoid division issues
        vm.assume(blockNumber > 256);
        vm.assume(blockNumber < type(uint128).max);
        
        // salt % 5 must not be 0 to avoid division by zero
        // salt is set to block.timestamp at deployment, so we need timestamp % 5 != 0
        vm.assume(blockTimestamp % 5 != 0);
        
        // Ensure seed calculation doesn't overflow and produces valid blockhash
        uint256 salt = blockTimestamp;
        uint256 y = salt * blockNumber / (salt % 5);
        uint256 seed = blockNumber / 3 + (salt % 300) + y;
        
        // blockhash only works for the 256 most recent blocks
        vm.assume(seed < blockNumber);
        vm.assume(blockNumber - seed <= 256);
        
        uint256 max = 100;
        
        // Avoid division by zero in x calculation
        vm.assume(salt * 100 / max > 0);

        // --- 2. State Configuration ---
        
        // Set the block timestamp before deploying the contract
        // This is important because salt is set in the constructor
        vm.warp(blockTimestamp);
        
        // Deploy a fresh contract with our controlled timestamp
        RandomNumberGenerator testRng = new RandomNumberGenerator();
        
        // Set the block number for the random call
        vm.roll(blockNumber);
        
        // Set a known blockhash for the seed block
        bytes32 knownBlockHash = keccak256(abi.encodePacked(blockTimestamp, blockNumber, seed));
        vm.store(
            address(vm),
            bytes32(seed),
            knownBlockHash
        );

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable logic locally
        // salt was set to blockTimestamp at deployment
        uint256 predictedSalt = blockTimestamp;
        uint256 predictedX = predictedSalt * 100 / max;
        uint256 predictedY = predictedSalt * blockNumber / (predictedSalt % 5);
        uint256 predictedSeed = blockNumber / 3 + (predictedSalt % 300) + predictedY;
        
        // Get the blockhash that the contract will use
        bytes32 seedBlockHash = blockhash(predictedSeed);
        uint256 predictedH = uint256(seedBlockHash);
        
        // Calculate the predicted random number
        uint256 predictedResult;
        if (predictedX > 0) {
            predictedResult = uint256((predictedH / predictedX)) % max + 1;
        } else {
            predictedResult = 1;
        }
        
        // Execute the contract method
        uint256 actualResult = testRng.random(max);
        
        // Assert predictability - the random value should match our prediction
        assertEq(actualResult, predictedResult, "Random number was predictable");
        
        // Additional assertion: verify the result is within expected bounds
        assertGe(actualResult, 1, "Result should be >= 1");
        assertLe(actualResult, max, "Result should be <= max");
    }
}
