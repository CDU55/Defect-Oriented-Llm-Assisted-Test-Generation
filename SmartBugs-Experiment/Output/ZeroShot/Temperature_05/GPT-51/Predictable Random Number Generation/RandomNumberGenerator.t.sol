
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {
    RandomNumberGenerator rng;

    function setUp() public {
        rng = new RandomNumberGenerator();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber, uint256 max) public {
        // --- 1. Constraints ---
        vm.assume(blockTimestamp > 0);
        vm.assume(blockNumber > 10); // ensure block.number / 3 is small enough and seed is in a sane range
        vm.assume(max > 1 && max < type(uint256).max / 100); // avoid overflow in salt * 100 / max

        // --- 2. State Configuration ---
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---

        // Recompute the contract's internal randomness logic
        uint256 salt = block.timestamp;
        vm.assume(salt % 5 != 0); // avoid division by zero in y computation

        uint256 x = salt * 100 / max;
        uint256 y = salt * block.number / (salt % 5);
        uint256 seed = block.number / 3 + (salt % 300) + y;
        uint256 h = uint256(blockhash(seed));
        uint256 expected = uint256((h / x)) % max + 1;

        uint256 actual = rng.random(max);

        assertEq(actual, expected, "Random output should be predictable from block data");
    }
}
