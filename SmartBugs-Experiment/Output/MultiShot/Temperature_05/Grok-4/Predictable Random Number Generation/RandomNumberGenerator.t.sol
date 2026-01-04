
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {

    RandomNumberGenerator public _contractUnderTest;

    function setUp() public {
        
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber, uint256 max) public {
        
        // --- 1. Constraints ---
        
        vm.assume(blockTimestamp >= block.timestamp);
        
        vm.assume(blockNumber >= block.number);
        
        vm.assume(max > 0);
        vm.assume(blockTimestamp % 5 != 0);
        vm.assume(blockTimestamp <= type(uint256).max / 100);
        vm.assume(blockNumber == 0 || blockTimestamp <= type(uint256).max / blockNumber);
        vm.assume(blockTimestamp < 2**128);
        vm.assume(blockNumber < 2**128);
        vm.assume(max < 2**128);

        // --- 2. State Configuration ---
        
        
        vm.warp(blockTimestamp);
        _contractUnderTest = new RandomNumberGenerator();
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        uint256 salt_ = blockTimestamp;
        uint256 x = salt_ * 100 / max;
        uint256 y = salt_ * blockNumber / (salt_ % 5);
        uint256 seed = blockNumber / 3 + (salt_ % 300) + y;
        uint256 h = uint256(blockhash(seed));
        uint256 expectedRandom = (h / x) % max + 1;
        
        uint256 actualRandom = _contractUnderTest.random(max);

        
        assertEq(actualRandom, expectedRandom, "Randomness should be predictable given block state");
    }
}
