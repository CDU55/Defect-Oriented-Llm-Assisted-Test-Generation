
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

        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 salt = blockTimestamp;
        uint256 x = salt * 100 / 1000;
        uint256 y = salt * blockNumber / (salt % 5);
        uint256 seed = blockNumber / 3 + (salt % 300) + y;
        uint256 h = uint256(blockhash(seed));
        uint256 expectedRandom = uint256((h / x)) % 1000 + 1;

        uint256 actualRandom = _contractUnderTest.random(1000);

        assertEq(actualRandom, expectedRandom, "Randomness should be predictable given block state");
    }
}
