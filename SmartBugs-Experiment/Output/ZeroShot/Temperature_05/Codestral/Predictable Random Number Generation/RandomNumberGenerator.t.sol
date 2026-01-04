
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {

    RandomNumberGenerator public rng;

    function setUp() public {
        rng = new RandomNumberGenerator();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        uint256 max = 100;

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 salt = blockTimestamp;
        uint256 x = salt * 100 / max;
        uint256 y = salt * blockNumber / (salt % 5);
        uint256 seed = blockNumber / 3 + (salt % 300) + y;
        uint256 h = uint256(blockhash(seed));
        uint256 expected = uint256((h / x)) % max + 1;

        uint256 actual = rng.random(max);

        assertEq(actual, expected, "Random number should be predictable");
    }
}
