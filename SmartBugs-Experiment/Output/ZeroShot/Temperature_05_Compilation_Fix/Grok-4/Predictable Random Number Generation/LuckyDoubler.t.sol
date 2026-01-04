
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {

    LuckyDoubler luckyDoubler;

    function setUp() public {
        luckyDoubler = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockNumber >= 2);
        
        // --- 2. State Configuration ---
        
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.deal(user1, 2 ether);
        vm.deal(user2, 2 ether);
        
        vm.roll(blockNumber);
        
        vm.prank(user1);
        payable(luckyDoubler).transfer(1 ether);
        
        // --- 3. Replication & Assertion ---
        
        uint256 FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
        uint max = 2;
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));
        uint256 predictedResult = uint256((hashVal / factor)) % max;
                
        vm.prank(user2);
        payable(luckyDoubler).transfer(1 ether);

        (, , bool paid0, ) = luckyDoubler.entryDetails(0);
        (, , bool paid1, ) = luckyDoubler.entryDetails(1);

        if (predictedResult == 0) {
            assertTrue(paid0);
            assertFalse(paid1);
        } else {
            assertFalse(paid0);
            assertTrue(paid1);
        }
    }
}
