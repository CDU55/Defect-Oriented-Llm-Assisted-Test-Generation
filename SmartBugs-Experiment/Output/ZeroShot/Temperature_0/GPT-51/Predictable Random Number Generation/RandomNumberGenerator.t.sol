
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
        vm.assume(blockNumber > 10);
        vm.assume(max > 1);

        // --- 2. State Configuration ---
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        uint256 salt = block.timestamp;

        uint256 x = salt * 100 / max;
        vm.assume(salt % 5 != 0);
        uint256 y = salt * block.number / (salt % 5);
        uint256 seed = block.number / 3 + (salt % 300) + y;
        uint256 h = uint256(blockhash(seed));
        uint256 expected = uint256((h / x)) % max + 1;

        uint256 actual = rng.random(max);

        assertEq(actual, expected, "Random output is predictable from block data");
    }
}
