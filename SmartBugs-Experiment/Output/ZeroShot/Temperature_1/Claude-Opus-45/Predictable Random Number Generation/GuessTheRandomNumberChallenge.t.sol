
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {

    GuessTheRandomNumberChallenge public challenge;
    
    uint256 deployBlockNumber;
    uint256 deployBlockTimestamp;

    function setUp() public {
        deployBlockNumber = block.number;
        deployBlockTimestamp = block.timestamp;
        
        challenge = new GuessTheRandomNumberChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        
        // --- 1. Constraints ---
        vm.assume(blockNumber > 1);
        vm.assume(blockNumber < type(uint256).max - 1000);
        vm.assume(blockTimestamp > 0);
        vm.assume(blockTimestamp < type(uint256).max - 1000);

        // --- 2. State Configuration ---
        
        vm.deal(address(this), 2 ether);
        
        vm.roll(blockNumber);
        vm.warp(blockTimestamp);
        
        // Deploy the challenge contract at this specific block state
        GuessTheRandomNumberChallenge targetChallenge = new GuessTheRandomNumberChallenge{value: 1 ether}();

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable random number generation logic
        // The answer is computed using blockhash(block.number - 1) and block.timestamp at deployment
        uint8 predictedAnswer = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber - 1), blockTimestamp))));
        
        // Verify the challenge is not complete before our guess
        assertFalse(targetChallenge.isComplete(), "Challenge should not be complete before guessing");
        
        // Execute the guess with our predicted answer
        targetChallenge.guess{value: 1 ether}(predictedAnswer);
        
        // Assert that we successfully predicted the random value by checking the challenge is complete
        assertTrue(targetChallenge.isComplete(), "Challenge should be complete after correct guess - randomness was predictable");
    }
    
    receive() external payable {}
}
