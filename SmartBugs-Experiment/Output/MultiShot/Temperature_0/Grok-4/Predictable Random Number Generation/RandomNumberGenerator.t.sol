
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {

    RandomNumberGenerator public _contractUnderTest;

    function setUp() public {
        
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        
        vm.assume(blockTimestamp >= block.timestamp);
        
        vm.assume(blockNumber >= block.number);
        
        vm.assume(blockTimestamp >= 1);
        vm.assume(blockTimestamp % 5 != 0);
        vm.assume(blockNumber > 0);
        vm.assume(blockTimestamp <= type(uint256).max / blockNumber);
        vm.assume(blockTimestamp <= type(uint256).max / 100);
        

        // --- 2. State Configuration ---
        
        
        vm.warp(blockTimestamp);
        _contractUnderTest = new RandomNumberGenerator();
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        uint256 maxVal = 100;
        uint256 salt_ = blockTimestamp;
        uint256 x = salt_ * 100 / maxVal;
        uint256 y = salt_ * blockNumber / (salt_ % 5);
        uint256 seed_ = blockNumber / 3 + (salt_ % 300) + y;
        uint256 h;
        uint256 current = blockNumber;
        if (seed_ < current && seed_ >= current - 255) {
            h = uint256(keccak256(abi.encodePacked(seed_)));
        } else {
            h = 0;
        }
        uint256 expected = uint256((h / x)) % maxVal + 1;
        
        uint256 actualRandom = _contractUnderTest.random(maxVal);

        
        assertEq(actualRandom, expected, "Randomness should be predictable given block state");
    }
}
