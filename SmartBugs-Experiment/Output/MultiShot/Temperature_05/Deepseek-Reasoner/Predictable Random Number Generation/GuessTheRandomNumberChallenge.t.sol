
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {
    GuessTheRandomNumberChallenge public _contractUnderTest;

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= 1);
        vm.assume(blockNumber >= 1);
        
        vm.deal(address(this), 2 ether);
        
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);
        
        bytes32 prevBlockHash = blockhash(blockNumber - 1);
        uint8 expectedAnswer = uint8(uint256(keccak256(abi.encodePacked(prevBlockHash, blockTimestamp))));
        
        _contractUnderTest = new GuessTheRandomNumberChallenge{value: 1 ether}();
        
        uint8 computedAnswer = uint8(uint256(keccak256(abi.encodePacked(prevBlockHash, blockTimestamp))));
        
        _contractUnderTest.guess{value: 1 ether}(expectedAnswer);
        
        assertTrue(_contractUnderTest.isComplete(), "Randomness should be predictable given block state");
    }
}
