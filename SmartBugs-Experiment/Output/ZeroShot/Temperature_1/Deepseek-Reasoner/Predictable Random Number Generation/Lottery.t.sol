
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {
    Lottery lottery;

    function setUp() public {
        lottery = new Lottery();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        // --- 1. Constraints ---
        // No overflow constraints needed as block.number is uint256 by default
        // and the contract uses modulo 2 operation which is safe
        
        // --- 2. State Configuration ---
        address player = address(0x123);
        uint256 betAmount = 1 ether;
        vm.deal(player, betAmount);

        // --- 2. MANIPULATE BLOCK ENVIRONMENT ---
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        // PREDICT THE OUTCOME
        // Replicate the vulnerable logic: won = (block.number % 2) == 0
        bool expectedWon = (blockNumber % 2) == 0;
        
        // EXECUTE
        vm.prank(player);
        lottery.makeBet{value: betAmount}();

        // ASSERT PREDICTABILITY
        // Check contract balance to verify win/loss outcome
        if (expectedWon) {
            // Player should get money back - contract balance remains same
            assertEq(address(lottery).balance, 0);
        } else {
            // Contract keeps the money
            assertEq(address(lottery).balance, betAmount);
        }
    }
}
