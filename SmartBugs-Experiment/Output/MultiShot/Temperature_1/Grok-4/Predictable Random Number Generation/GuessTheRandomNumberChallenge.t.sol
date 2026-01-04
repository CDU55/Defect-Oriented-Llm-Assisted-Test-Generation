
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {

    GuessTheRandomNumberChallenge public _contractUnderTest;

    function setUp() public {
        
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        
        vm.assume(blockTimestamp >= block.timestamp);
        
        vm.assume(blockNumber >= block.number);
        
        vm.assume(blockNumber >= 1);

        // --- 2. State Configuration ---
        
        vm.deal(address(this), 2 ether);

        
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        _contractUnderTest = new GuessTheRandomNumberChallenge{value: 1 ether}();
        
        uint8 expectedRandom = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber - 1), blockTimestamp))));
        
        _contractUnderTest.guess{value: 1 ether}(expectedRandom);

        
        assertTrue(_contractUnderTest.isComplete(), "Randomness should be predictable given block state");
    }
}
