
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {

    RandomNumberGenerator public _contractUnderTest;

    function setUp() public {
        // Deployment is handled in the test to allow fuzzing the deployment timestamp (salt)
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber, uint256 max) public {
        
        // --- 1. Constraints ---
        
        // Constraint for 'salt' (blockTimestamp):
        // The contract calculates (salt % 5), so we must ensure this is not 0 to avoid division by zero.
        vm.assume(blockTimestamp % 5 != 0);
        
        // Constraint for 'max':
        // Must be greater than 0 for modulo operations.
        vm.assume(max > 0);
        
        // Constraint for 'x' calculation:
        // x = salt * 100 / max. The contract performs (h / x), so x must not be 0.
        // This implies salt * 100 >= max.
        // We also check for overflow on salt * 100.
        vm.assume(blockTimestamp > 0);
        vm.assume(blockTimestamp < type(uint256).max / 100);
        vm.assume(blockTimestamp * 100 >= max);

        // Constraint for 'blockNumber':
        vm.assume(blockNumber > 0);
        
        // Avoid arithmetic overflow in 'y' calculation: y = salt * blockNumber / ...
        unchecked {
            vm.assume(type(uint256).max / blockTimestamp >= blockNumber);
        }

        // --- 2. State Configuration ---
        
        // Set the timestamp for deployment, which sets the private 'salt' variable.
        vm.warp(blockTimestamp);
        _contractUnderTest = new RandomNumberGenerator();

        // Set the block number for the execution of the random function.
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable logic locally
        uint256 salt = blockTimestamp;
        uint256 x = salt * 100 / max;
        uint256 y = salt * blockNumber / (salt % 5);
        uint256 seed = blockNumber / 3 + (salt % 300) + y;
        
        // Replicate blockhash behavior
        uint256 h = uint256(blockhash(seed));
        
        uint256 expectedRandom = uint256((h / x)) % max + 1;
        
        // Execute
        uint256 actualRandom = _contractUnderTest.random(max);

        // Assert Predictability
        assertEq(actualRandom, expectedRandom, "Randomness should be predictable given block state");
    }
}
