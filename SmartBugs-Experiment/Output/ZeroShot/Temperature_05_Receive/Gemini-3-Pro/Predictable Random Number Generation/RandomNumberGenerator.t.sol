
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {

    RandomNumberGenerator rng;
    uint256 constant SALT_TIMESTAMP = 1234567;

    function setUp() public {
        // Initialize the contract under test.
        // We warp to a specific timestamp to ensure 'salt' is known and satisfies (salt % 5 != 0).
        // 1234567 % 5 = 2.
        vm.warp(SALT_TIMESTAMP);
        rng = new RandomNumberGenerator();
    }

    // INFER BLOCK DEPENDENCIES
    // The contract uses block.number in the random function.
    // We also fuzz 'max' as it is an input parameter.
    function test_highlightPredictableRandomValue(uint256 executionBlockNumber, uint256 max) public {
        
        // --- 1. Constraints ---
        // Ensure x > 0 to avoid division by zero in contract logic (h / x).
        // x = salt * 100 / max. We need salt * 100 >= max.
        // Also max must be > 0.
        max = bound(max, 1, SALT_TIMESTAMP * 100);
        
        // Avoid arithmetic overflows in y calculation and seed calculation.
        // y = salt * block.number ...
        // We constrain block number to a realistic range (uint64) to prevent overflow when multiplied by salt.
        executionBlockNumber = bound(executionBlockNumber, 1, type(uint64).max);

        // --- 2. State Configuration ---
        
        // MANIPULATE BLOCK ENVIRONMENT
        vm.roll(executionBlockNumber);

        // --- 3. Replication & Assertion ---
        
        // PREDICT THE OUTCOME
        // Replicate the vulnerable logic locally inside the test.
        uint256 salt = SALT_TIMESTAMP;
        uint256 x = salt * 100 / max;
        uint256 y = salt * executionBlockNumber / (salt % 5);
        uint256 seed = executionBlockNumber / 3 + (salt % 300) + y;
        uint256 h = uint256(blockhash(seed));
        
        uint256 expected = uint256((h / x)) % max + 1;
                
        // EXECUTE
        uint256 actual = rng.random(max);

        // ASSERT PREDICTABILITY
        assertEq(actual, expected, "Random value should be predictable");
    }

    receive() external payable {}

    fallback() external payable {}
}
