
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {
    RandomNumberGenerator randomNumberGenerator;

    function setUp() public {
        randomNumberGenerator = new RandomNumberGenerator();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        
        vm.assume(blockNumber > 0);
        vm.assume(blockNumber < type(uint256).max / 300);
        vm.assume(blockTimestamp > 0);
        vm.assume(blockTimestamp % 5 != 0);
        vm.assume(blockTimestamp < type(uint256).max / 100);

        uint256 salt = blockTimestamp;
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 max = 100;
        uint256 x = salt * 100 / max;
        uint256 y = salt * blockNumber / (salt % 5);
        uint256 seed = blockNumber / 3 + (salt % 300) + y;
        
        bytes32 blockHash = keccak256(abi.encode(seed));
        vm.store(address(randomNumberGenerator), bytes32(uint256(0)), bytes32(salt));
        vm.store(address(block), bytes32(uint256(8) + seed % 256), blockHash);

        uint256 expected = (uint256(blockHash) / x) % max + 1;
        uint256 result = randomNumberGenerator.random(max);
        
        assertEq(result, expected);
    }
}
