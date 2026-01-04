
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {
    RandomNumberGenerator randomGenerator;
    uint256 constant FIXED_MAX = 100;

    function setUp() public {
        randomGenerator = new RandomNumberGenerator();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber, bytes32 blockHashValue) public {
        
        vm.assume(blockTimestamp > 0);
        vm.assume(blockNumber > 0 && blockNumber < 256);
        vm.assume(uint256(blockHashValue) > 0);
        vm.assume(blockTimestamp % 5 != 0);
        
        uint256 salt = blockTimestamp;
        
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);
        
        uint256 seed = blockNumber / 3 + (salt % 300) + (salt * blockNumber / (salt % 5));
        
        if (seed < blockNumber && seed >= blockNumber - 256) {
            vm.mockBlockHash(seed, blockHashValue);
        } else {
            return;
        }
        
        uint256 x = salt * 100 / FIXED_MAX;
        uint256 h = uint256(blockHashValue);
        uint256 expectedRandom = (h / x) % FIXED_MAX + 1;
        
        uint256 actualRandom = randomGenerator.random(FIXED_MAX);
        
        assertEq(actualRandom, expectedRandom);
    }
}
