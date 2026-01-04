
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
        vm.assume(max > 1 && max < type(uint256).max / 100);
        vm.assume(blockTimestamp > 0);
        // Need salt % 5 != 0 to avoid division by zero in y
        vm.assume(blockTimestamp % 5 != 0);
        // Avoid block.number / 3 overflowing seed/blockhash domain assumptions
        vm.assume(blockNumber > 10);

        // --- 2. State Configuration ---
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        // Reproduce the contract's internal logic using the known block values.
        uint256 salt = blockTimestamp;

        uint256 x = salt * 100 / max;
        uint256 y = salt * blockNumber / (salt % 5);
        uint256 seed = blockNumber / 3 + (salt % 300) + y;
        uint256 h = uint256(blockhash(seed));

        uint256 expected = uint256((h / x)) % max + 1;

        uint256 onchain = rng.random(max);

        assertEq(onchain, expected, "Random output should be predictable from block data");
    }
}
