
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {

    RandomNumberGenerator public rng;

    function setUp() public {
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        vm.assume(blockTimestamp > 0);
        vm.assume(blockTimestamp % 5 != 0);
        vm.assume(blockNumber > 0);
        bound(blockTimestamp, 1, type(uint64).max);
        bound(blockNumber, 1, type(uint64).max);
        vm.assume(blockTimestamp <= type(uint256).max / blockNumber);
        vm.assume(blockTimestamp <= type(uint256).max / 100);
        
        vm.warp(blockTimestamp);
        rng = new RandomNumberGenerator();
        vm.roll(blockNumber);
        
        uint256 salt = blockTimestamp;
        uint256 max = 10;
        uint256 x = salt * 100 / max;
        uint256 y = salt * blockNumber / (salt % 5);
        uint256 seed_ = blockNumber / 3 + (salt % 300) + y;
        uint256 h = uint256(blockhash(seed_));
        uint256 expected = (h / x) % max + 1;
                
        uint256 result = rng.random(max);

        assertEq(result, expected);
    }

    receive() external payable {}

    fallback() external payable {}
}
