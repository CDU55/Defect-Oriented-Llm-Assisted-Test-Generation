
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {
    RandomNumberGenerator public _contractUnderTest;

    function setUp() public {
        vm.warp(1000);
        vm.roll(10);
        _contractUnderTest = new RandomNumberGenerator();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= 1);
        vm.assume(blockNumber >= 1);
        vm.assume(blockTimestamp < type(uint256).max / 100);
        vm.assume(blockNumber < type(uint256).max / 3);
        vm.assume(blockNumber < type(uint256).max / 100);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);
        
        _contractUnderTest = new RandomNumberGenerator();

        uint256 max = 100;
        uint256 salt = blockTimestamp;
        
        uint256 x = salt * 100 / max;
        uint256 y = salt * blockNumber / (salt % 5 == 0 ? 1 : salt % 5);
        uint256 seed = blockNumber / 3 + (salt % 300) + y;
        
        bytes32 blockHash;
        if (seed < blockNumber && seed >= blockNumber - 256) {
            blockHash = blockhash(seed);
        }
        uint256 h = uint256(blockHash);
        uint256 expectedRandom = uint256((h / x)) % max + 1;

        uint256 actualRandom = _contractUnderTest.random(max);

        assertEq(actualRandom, expectedRandom, "Randomness should be predictable given block state");
    }
}
