
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {

    RandomNumberGenerator rng;

    function setUp() public {
        // Initialize the contract under test.
        // We set a specific timestamp to control the 'salt' variable initialized in the constructor.
        // We must ensure 'salt % 5 != 0' to avoid a division by zero error in the 'random' function.
        uint256 deployTimestamp = 1000001; 
        if (deployTimestamp % 5 == 0) {
            deployTimestamp++;
        }
        
        vm.warp(deployTimestamp);
        rng = new RandomNumberGenerator();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 max) public {
        
        // --- 1. Constraints ---
        vm.assume(max > 0);
        vm.assume(blockNumber > 0);
        
        // Retrieve the private 'salt' variable from storage slot 0
        uint256 salt = uint256(vm.load(address(rng), bytes32(uint256(0))));
        
        // Ensure 'x' will not be zero to avoid division by zero (h / x) later
        // x = salt * 100 / max
        vm.assume(salt * 100 >= max);

        // --- 2. State Configuration ---
        
        // Set the block number to influence the randomness calculation
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable logic locally inside the test
        uint256 x = salt * 100 / max;
        uint256 y = salt * blockNumber / (salt % 5);
        uint256 seed = blockNumber / 3 + (salt % 300) + y;
        uint256 h = uint256(blockhash(seed));
        
        uint256 expectedResult = uint256((h / x)) % max + 1;
                
        // Execute the contract method
        // Note: This assumes the 'random' function is accessible (e.g., public) for testing.
        uint256 actualResult = rng.random(max);

        // Assert Predictability
        assertEq(actualResult, expectedResult, "The random number generated should match the predicted value");
    }
}
