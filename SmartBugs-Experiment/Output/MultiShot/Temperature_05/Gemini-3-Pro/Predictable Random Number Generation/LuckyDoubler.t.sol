
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {

    LuckyDoubler public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        // Ensure blockNumber is valid for blockhash calculation (must be > 0)
        vm.assume(blockNumber > 10);

        // --- 2. State Configuration ---
        address user1 = address(0x1111);
        address user2 = address(0x2222);
        vm.deal(user1, 2 ether);
        vm.deal(user2, 2 ether);

        // User 1 deposits 1 ETH.
        // This initializes the contract state with one entry.
        // Balance increases (0.95 ETH), but not enough to trigger a payout (1.25 ETH) yet.
        vm.prank(user1);
        (bool success1, ) = address(_contractUnderTest).call{value: 1 ether}("");
        require(success1, "User 1 deposit failed");

        // Manipulate block environment
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // PREDICT THE OUTCOME
        // Replicate the logic from LuckyDoubler.rand()
        // When User 2 deposits, unpaidEntries.length will be 2 (User 1 at index 0, User 2 at index 1).
        uint256 max = 2; 
        uint256 FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
        
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));
        
        // Calculate the index that will be selected by the contract
        uint256 predictedIndex = uint256((uint256(hashVal) / factor)) % max;
        
        // Map index to user address
        // Index 0 is User 1 (first depositor), Index 1 is User 2 (current depositor)
        address predictedWinner = predictedIndex == 0 ? user1 : user2;
        uint256 winnerInitialBalance = predictedWinner.balance;

        // EXECUTE
        // User 2 deposits 1 ETH.
        // This triggers the join() logic, adds User 2, and executes the payout based on rand().
        // New Balance = 0.95 + 0.95 = 1.9 ETH. Payout needed = 1.25 ETH. Payout triggers.
        vm.prank(user2);
        (bool success2, ) = address(_contractUnderTest).call{value: 1 ether}("");
        require(success2, "User 2 deposit failed");

        // ASSERT PREDICTABILITY
        // The payout is 1.25 ETH (125% of 1 ETH)
        uint256 payoutAmount = 1.25 ether;
        
        if (predictedWinner == user2) {
            // User 2 spent 1 ether and received payout
            assertEq(user2.balance, winnerInitialBalance - 1 ether + payoutAmount, "Randomness should be predictable: User 2 expected to win");
        } else {
            // User 1 received payout
            assertEq(user1.balance, winnerInitialBalance + payoutAmount, "Randomness should be predictable: User 1 expected to win");
        }
    }
}
