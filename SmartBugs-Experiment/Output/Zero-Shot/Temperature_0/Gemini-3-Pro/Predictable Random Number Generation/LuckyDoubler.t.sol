
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {

    LuckyDoubler luckyDoubler;

    function setUp() public {
        luckyDoubler = new LuckyDoubler();
    }

    // function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
    //     // --- 1. Constraints ---
    //     // Ensure blockNumber is valid for blockhash retrieval (not 0)
    //     blockNumber = bound(blockNumber, 10, 1000000);
        
    //     // --- 2. State Configuration ---
        
    //     address user1 = makeAddr("user1");
    //     address user2 = makeAddr("user2");
    //     vm.deal(user1, 2 ether);
    //     vm.deal(user2, 2 ether);

    //     // User 1 joins first to populate the system
    //     vm.prank(user1);
    //     luckyDoubler.init{value: 1 ether}();

    //     // Set the block number to the target value where the attack (User 2 join) will happen
    //     vm.roll(blockNumber);

    //     // --- 3. Replication & Assertion ---
        
    //     // Replicate the vulnerable logic locally inside the test.
    //     // The contract uses blockhash(block.number - 1) to determine the winner.
        
    //     uint256 FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
        
    //     // When User 2 joins, there will be 2 unpaid entries in the array (User 1 at index 0, User 2 at index 1).
    //     uint256 max = 2; 
        
    //     uint256 factor = FACTOR * 100 / max;
    //     uint256 lastBlockNumber = block.number - 1;
    //     uint256 hashVal = uint256(blockhash(lastBlockNumber));

    //     // Calculate the index that the contract will select
    //     uint256 expectedIndex = uint256((uint256(hashVal) / factor)) % max;

    //     // Determine who is expected to win based on the calculated index
    //     // Index 0 corresponds to user1 (first joiner)
    //     // Index 1 corresponds to user2 (second joiner)
    //     address expectedWinner = expectedIndex == 0 ? user1 : user2;
        
    //     uint256 winnerBalanceBefore = expectedWinner.balance;

    //     // EXECUTE
    //     // User 2 joins, triggering the payout logic
    //     vm.prank(user2);
    //     luckyDoubler.init{value: 1 ether}();

    //     // ASSERT PREDICTABILITY
    //     // Verify that the payout went to the address we predicted based on the blockhash.
    //     // Payout amount is 1 ether * 125% = 1.25 ether.
        
    //     uint256 winnerBalanceAfter = expectedWinner.balance;
        
    //     if (expectedWinner == user2) {
    //         // If User 2 wins: They spent 1 ETH and received 1.25 ETH. Net change: +0.25 ETH.
    //         assertEq(winnerBalanceAfter, winnerBalanceBefore - 1 ether + 1.25 ether, "Predictable randomness failed: User 2 should have won");
    //     } else {
    //         // If User 1 wins: They spent nothing in this transaction and received 1.25 ETH. Net change: +1.25 ETH.
    //         assertEq(winnerBalanceAfter, winnerBalanceBefore + 1.25 ether, "Predictable randomness failed: User 1 should have won");
    //     }
    // }
}
