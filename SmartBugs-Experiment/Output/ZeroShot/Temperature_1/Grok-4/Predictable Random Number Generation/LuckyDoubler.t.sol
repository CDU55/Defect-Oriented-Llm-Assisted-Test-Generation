
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
        vm.assume(blockNumber > 1);
        
        

        // --- 2. State Configuration ---
        
        vm.roll(blockNumber);
        
        address user1 = makeAddr("user1");
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        (bool sent,) = address(luckyDoubler).call{value: 1 ether}("");
        assertTrue(sent);

        // --- 3. Replication & Assertion ---
        
        uint max = 2;
        uint256 constant FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumberLocal = block.number - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumberLocal));
        uint256 expected_rand = uint256((hashVal / factor) % max);
                
        address user2 = makeAddr("user2");
        vm.deal(user2, 1 ether);
        vm.prank(user2);
        (sent,) = address(luckyDoubler).call{value: 1 ether}("");
        assertTrue(sent);

        (, , bool paid0, ) = luckyDoubler.entryDetails(0);
        (, , bool paid1, ) = luckyDoubler.entryDetails(1);

        if (expected_rand == 0) {
            assertTrue(paid0);
            assertFalse(paid1);
        } else {
            assertFalse(paid0);
            assertTrue(paid1);
        }
    }
}
