
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {

    GuessTheRandomNumberChallenge public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 2 ether);
        _contractUnderTest = new GuessTheRandomNumberChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(type(uint256).max - blockNumber >= blockTimestamp);

        vm.deal(address(this), 1 ether);
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 blockHash = uint256(blockhash(blockNumber - 1));
        uint256 expectedAnswer = uint8(uint256(keccak256(abi.encodePacked(blockHash, blockTimestamp))));

        uint8 actualAnswer = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))));

        assertEq(actualAnswer, expectedAnswer, "Randomness should be predictable given block state");
    }
}
