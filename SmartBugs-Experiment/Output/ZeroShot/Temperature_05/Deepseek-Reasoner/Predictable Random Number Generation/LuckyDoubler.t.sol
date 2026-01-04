
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {
    LuckyDoubler public luckyDoubler;

    function setUp() public {
        luckyDoubler = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, bytes32 blockHashValue) public {
        
        // --- 1. Constraints ---
        vm.assume(blockNumber > 0 && blockNumber < 256); // blockhash only works for last 256 blocks
        vm.assume(blockHashValue != 0); // blockhash returns 0 for non-existent blocks
        
        // Avoid arithmetic overflow in rand calculation
        uint256 maxEntries = 2;
        vm.assume(blockHashValue <= type(uint256).max / 100);

        // --- 2. State Configuration ---
        
        // Fund two users to create multiple unpaid entries
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        vm.deal(alice, 2 ether);
        vm.deal(bob, 2 ether);
        
        // Alice deposits first (creates 1 unpaid entry)
        vm.prank(alice);
        (bool successAlice,) = address(luckyDoubler).call{value: 1 ether}("");
        require(successAlice, "Alice deposit failed");
        
        // Set block environment before Bob's deposit
        vm.roll(blockNumber + 1); // Set current block number
        vm.blockhash(blockNumber, blockHashValue); // Set hash of previous block

        // --- 3. Replication & Assertion ---
        
        // PREDICT THE OUTCOME: Replicate the rand logic
        uint256 factor = 1157920892373161954235709850086879078532699846656405640394575840079131296399 * 100 / maxEntries;
        uint256 predictedRandom = (uint256(blockHashValue) / factor) % maxEntries;
        
        // EXECUTE: Bob deposits (this will trigger rand with 2 unpaid entries)
        vm.prank(bob);
        (bool successBob,) = address(luckyDoubler).call{value: 1 ether}("");
        require(successBob, "Bob deposit failed");
        
        // ASSERT PREDICTABILITY: Verify contract used predictable randomness
        // If predictedRandom was 0, Alice's entry should have been paid
        // If predictedRandom was 1, Bob's entry should have been paid immediately
        // We can check by verifying at least one entry was paid
        (address user0, uint256 payout0, bool paid0,) = luckyDoubler.entryDetails(0);
        (address user1, uint256 payout1, bool paid1,) = luckyDoubler.entryDetails(1);
        
        // The vulnerable rand function should have selected an entry to pay
        // Since we controlled the blockhash, we predicted which one
        if (predictedRandom == 0) {
            assertTrue(paid0, "Entry 0 should have been paid based on predictable random");
        } else {
            assertTrue(paid1, "Entry 1 should have been paid based on predictable random");
        }
        
        // Additional check: The random selection was deterministic
        // We can show that with the same blockhash, we get the same result
        uint256 testBlockNumber = block.number - 1;
        bytes32 testBlockHash = blockhash(testBlockNumber);
        uint256 recalculatedRandom = (uint256(testBlockHash) / factor) % maxEntries;
        assertEq(recalculatedRandom, predictedRandom, "Random value should be reproducible with same blockhash");
    }
}
