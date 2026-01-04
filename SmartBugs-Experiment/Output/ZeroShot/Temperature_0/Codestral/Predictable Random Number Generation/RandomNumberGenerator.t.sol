
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {

    RandomNumberGenerator public contractUnderTest;

    function setUp() public {
        contractUnderTest = new RandomNumberGenerator();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        // --- 1. Constraints ---
        blockTimestamp = blockTimestamp + 1;
        blockNumber = blockNumber + 1;

        // --- 2. State Configuration ---
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        uint256 salt = blockTimestamp;
        uint256 x = salt * 100 / 100;
        uint256 y = salt * blockNumber / (salt % 5);
        uint256 seed = blockNumber / 3 + (salt % 300) + y;
        uint256 h = uint256(blockhash(seed));
        uint256 expected = uint256((h / x)) % 100 + 1;

        uint256 actual = contractUnderTest.random(100);

        assertEq(actual, expected, "Random number is predictable");
    }
}
