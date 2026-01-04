
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {

    LuckyDoubler luckyDoubler;

    function setUp() public {
        luckyDoubler = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        // Ensure blockNumber is high enough to have a valid previous block hash
        blockNumber = bound(blockNumber, 10, 1000000);
        
        // --- 2. State Configuration ---
        
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.deal(user1, 2 ether);
        vm.deal(user2, 2 ether);

        // Initial deposit to set up the state (1 entry in queue)
        // This ensures unpaidEntries.length will be > 1 on the next join
        vm.prank(user1);
        (bool success1, ) = address(luckyDoubler).call{value: 1 ether}("");
        require(success1, "User 1 deposit failed");

        // --- 3. Replication & Assertion ---
        
        // MANIPULATE BLOCK ENVIRONMENT
        vm.roll(blockNumber);

        // PREDICT THE OUTCOME
        // Replicate the logic from LuckyDoubler.rand()
        // When User 2 joins, unpaidEntries length will be 2. max = 2.
        uint256 max = 2;
        uint256 FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
        
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = blockNumber - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));
        
        // Calculate the index that the contract will select
        uint256 expectedIndex = uint256((uint256(hashVal) / factor)) % max;
                
        // EXECUTE
        // User 2 deposits, triggering the payout logic
        vm.prank(user2);
        (bool success2, ) = address(luckyDoubler).call{value: 1 ether}("");
        require(success2, "User 2 deposit failed");

        // ASSERT PREDICTABILITY
        // If expectedIndex is 0, User 1 (entry 0) should be paid.
        // If expectedIndex is 1, User 2 (entry 1) should be paid.
        
        (,, bool paidUser1, ) = luckyDoubler.entryDetails(0);
        (,, bool paidUser2, ) = luckyDoubler.entryDetails(1);

        if (expectedIndex == 0) {
            assertTrue(paidUser1, "Predicted index 0 (User 1) should be paid");
            assertFalse(paidUser2, "User 2 should not be paid yet");
        } else {
            assertFalse(paidUser1, "User 1 should not be paid yet");
            assertTrue(paidUser2, "Predicted index 1 (User 2) should be paid");
        }
    }
}
