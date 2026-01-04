
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {

    RandomNumberGenerator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new RandomNumberGenerator();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        // Constrain blockNumber to avoid division by zero and other edge cases
        vm.assume(blockNumber >= 10);
        vm.assume(blockNumber <= type(uint128).max);
        
        // The contract uses salt which is set to block.timestamp at deployment time
        // We need to ensure the seed calculation doesn't cause issues with blockhash
        // blockhash only works for the 256 most recent blocks
        uint256 deploymentTimestamp = block.timestamp;
        uint256 salt = deploymentTimestamp;
        
        // Ensure salt % 5 != 0 to avoid division by zero in the contract
        vm.assume(salt % 5 != 0);
        
        // Calculate seed to ensure it's within valid blockhash range
        uint256 y = salt * blockNumber / (salt % 5);
        uint256 seed = blockNumber / 3 + (salt % 300) + y;
        
        // Ensure seed is a valid block number for blockhash (within last 256 blocks)
        vm.assume(blockNumber > seed || seed <= 256);
        vm.assume(seed < blockNumber);
        vm.assume(blockNumber - seed <= 256);

        // --- 2. State Configuration ---
        
        // Set the block number
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Define max value for random number generation
        uint256 max = 100;
        vm.assume(max > 0);
        
        // Replicate the vulnerable logic locally
        // The salt was set at deployment time to block.timestamp
        uint256 x = salt * 100 / max;
        vm.assume(x > 0); // Avoid division by zero
        
        uint256 expectedY = salt * blockNumber / (salt % 5);
        uint256 expectedSeed = blockNumber / 3 + (salt % 300) + expectedY;
        uint256 h = uint256(blockhash(expectedSeed));
        uint256 expectedRandom = uint256((h / x)) % max + 1;
        
        // Execute the contract method
        uint256 actualRandom = _contractUnderTest.random(max);

        // Assert predictability - prove that the contract's "random" value matches our calculated expectation
        assertEq(actualRandom, expectedRandom, "Randomness should be predictable given block state");
    }
}
