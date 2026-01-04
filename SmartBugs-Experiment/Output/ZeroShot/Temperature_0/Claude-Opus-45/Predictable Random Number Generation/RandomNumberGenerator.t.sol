
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
        // Constrain blockTimestamp to avoid zero and ensure salt % 5 != 0 to prevent division by zero
        vm.assume(blockTimestamp > 0);
        vm.assume(blockTimestamp % 5 != 0);
        
        // Constrain blockNumber to be reasonable and avoid edge cases
        vm.assume(blockNumber > 256);
        vm.assume(blockNumber < type(uint128).max);
        
        // Ensure salt % 300 + other terms don't cause issues
        vm.assume(blockTimestamp < type(uint128).max);

        // --- 2. State Configuration ---
        
        // Deploy a new contract with the manipulated timestamp as salt
        vm.warp(blockTimestamp);
        RandomNumberGenerator targetRng = new RandomNumberGenerator();
        
        // Set the block number for the random calculation
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        uint256 max = 100;
        
        // Replicate the vulnerable logic locally
        // The salt is set to block.timestamp at deployment time
        uint256 salt = blockTimestamp;
        uint256 x = salt * 100 / max;
        
        // Avoid division by zero in x
        vm.assume(x > 0);
        
        uint256 y = salt * blockNumber / (salt % 5);
        uint256 seed = blockNumber / 3 + (salt % 300) + y;
        
        // Ensure seed is within valid blockhash range (last 256 blocks)
        // blockhash returns 0 for blocks outside the range [blockNumber - 256, blockNumber - 1]
        vm.assume(seed < blockNumber);
        vm.assume(seed >= blockNumber - 256 || seed == 0);
        
        uint256 h = uint256(blockhash(seed));
        
        // Calculate expected result
        uint256 expectedResult = uint256((h / x)) % max + 1;
        
        // Execute the contract method
        uint256 actualResult = targetRng.random(max);

        // Assert predictability - the contract's "random" value matches our calculated expectation
        assertEq(actualResult, expectedResult, "Random value should be predictable");
    }
}
