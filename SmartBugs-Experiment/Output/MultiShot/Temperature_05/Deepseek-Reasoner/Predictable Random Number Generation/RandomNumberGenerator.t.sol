
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {
    RandomNumberGenerator public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new RandomNumberGenerator();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= 1);
        vm.assume(blockNumber >= 1);
        vm.assume(blockTimestamp % 5 != 0);
        vm.assume(blockNumber / 3 + (blockTimestamp % 300) < blockNumber);
        vm.assume(blockTimestamp <= type(uint256).max / 100);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 salt = blockTimestamp;
        uint256 max = 1000;
        
        uint256 x = salt * 100 / max;
        uint256 y = salt * blockNumber / (salt % 5);
        uint256 seed = blockNumber / 3 + (salt % 300) + y;
        bytes32 blockHash = blockhash(seed);
        uint256 expectedRandom = uint256((uint256(blockHash) / x)) % max + 1;

        uint256 actualRandom = _contractUnderTest.random(max);
        
        assertEq(actualRandom, expectedRandom, "Randomness should be predictable given block state");
    }
}
