
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {
    RandomNumberGenerator public _contractUnderTest;
    uint256 public deploymentTimestamp;
    
    function setUp() public {
        deploymentTimestamp = block.timestamp;
        _contractUnderTest = new RandomNumberGenerator();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        vm.assume(blockTimestamp >= deploymentTimestamp);
        vm.assume(blockNumber >= block.number);
        
        uint256 salt = blockTimestamp;
        uint256 max = 100;
        vm.assume(max > 0);
        vm.assume(salt % 5 != 0);
        
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);
        
        uint256 x = salt * 100 / max;
        uint256 y = salt * blockNumber / (salt % 5);
        uint256 seed = blockNumber / 3 + (salt % 300) + y;
        
        bytes32 blockhashAtSeed = blockhash(seed);
        if (uint256(seed) >= block.number || uint256(seed) <= block.number - 256) {
            blockhashAtSeed = 0;
        }
        
        uint256 h = uint256(blockhashAtSeed);
        uint256 expectedRandom = (h / x) % max + 1;
        
        uint256 actualRandom = _contractUnderTest.random(max);
        
        assertEq(actualRandom, expectedRandom, "Randomness should be predictable given block state");
    }
}
