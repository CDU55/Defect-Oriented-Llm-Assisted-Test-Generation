
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {

    RandomNumberGenerator rng;

    function setUp() public {
        vm.warp(123456);
        rng = new RandomNumberGenerator();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockNumber > block.number);
        vm.assume(blockNumber <= type(uint256).max / 123456);
        vm.assume((123456 * blockNumber) <= type(uint256).max - (blockNumber / 3 + 156));
        
        // --- 2. State Configuration ---
        
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        uint256 salt = 123456;
        uint256 max_ = 100;
        uint256 x = salt * 100 / max_;
        uint256 y = salt * blockNumber / (salt % 5);
        uint256 seed = blockNumber / 3 + (salt % 300) + y;
        uint256 h = uint256(blockhash(seed));
        uint256 expected = uint256((h / x)) % max_ + 1;
                
        uint256 result = rng.random(max_);

        assertEq(result, expected);
    }
}
