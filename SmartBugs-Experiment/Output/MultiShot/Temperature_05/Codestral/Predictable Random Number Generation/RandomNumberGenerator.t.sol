
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {

    RandomNumberGenerator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new RandomNumberGenerator();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {

        // --- 1. Constraints ---
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(type(uint256).max - blockNumber >= blockTimestamp);

        // --- 2. State Configuration ---

        // --- 3. Replication & Assertion ---

        // PREDICT THE OUTCOME
        uint256 salt = blockTimestamp;
        uint256 x = salt * 100 / 1000; // Using 1000 as a sample max value
        uint256 y = salt * blockNumber / (salt % 5);
        uint256 seed = blockNumber / 3 + (salt % 300) + y;
        uint256 h = uint256(blockhash(seed));
        uint256 expectedRandom = uint256((h / x)) % 1000 + 1;

        // MANIPULATE BLOCK ENVIRONMENT
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // EXECUTE
        uint256 actualRandom = _contractUnderTest.random(1000);

        // ASSERT PREDICTABILITY
        assertEq(actualRandom, expectedRandom, "Randomness should be predictable given block state");
    }
}
