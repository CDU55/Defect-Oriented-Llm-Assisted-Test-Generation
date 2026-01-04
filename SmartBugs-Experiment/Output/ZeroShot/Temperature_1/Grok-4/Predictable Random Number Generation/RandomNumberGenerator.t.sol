
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {

    RandomNumberGenerator public rng;

    function setUp() public {
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockTimestamp > 0);
        vm.assume(blockNumber > 0);
        vm.assume(blockTimestamp % 5 != 0);
        vm.assume(blockTimestamp * blockNumber <= type(uint256).max);
        vm.assume(blockTimestamp * 100 <= type(uint256).max);
        
        // --- 2. State Configuration ---
        
        vm.warp(blockTimestamp);
        rng = new RandomNumberGenerator();
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        uint256 max = 100;
        uint256 x = blockTimestamp * 100 / max;
        uint256 y = blockTimestamp * blockNumber / (blockTimestamp % 5);
        uint256 seed = blockNumber / 3 + (blockTimestamp % 300) + y;
        uint256 h = uint256(blockhash(seed));
        uint256 expected = uint256((h / x)) % max + 1;
                
        uint256 result = rng.random(max);

        assertEq(result, expected);
    }
}
