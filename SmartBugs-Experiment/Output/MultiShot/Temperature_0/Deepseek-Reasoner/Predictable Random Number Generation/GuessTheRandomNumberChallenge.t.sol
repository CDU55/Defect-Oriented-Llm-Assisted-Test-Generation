
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {
    GuessTheRandomNumberChallenge public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 2 ether);
        _contractUnderTest = new GuessTheRandomNumberChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        vm.assume(blockNumber >= 1);
        vm.assume(blockNumber <= 256);
        vm.assume(blockTimestamp >= 1);
        
        vm.roll(blockNumber);
        vm.warp(blockTimestamp);
        
        uint8 predictedAnswer = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber - 1), blockTimestamp))));
        
        vm.deal(address(this), 2 ether);
        _contractUnderTest.guess{value: 1 ether}(predictedAnswer);
        
        assertTrue(_contractUnderTest.isComplete(), "Randomness should be predictable given block state");
    }
}
