
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
        assume(blockNumber >= 2);
        

        // --- 2. State Configuration ---
        
        vm.deal(address(this), 2 ether);

        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        payable(address(luckyDoubler)).transfer(1 ether);

        uint256 constant FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
        uint256 lastBlockNumber_ = block.number - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber_));
        uint max = 2;
        uint256 factor = FACTOR * 100 / max;
        uint256 expectedResult = (hashVal / factor) % max;
                
        payable(address(luckyDoubler)).transfer(1 ether);

        ( , , bool paid0, ) = luckyDoubler.entryDetails(0);
        ( , , bool paid1, ) = luckyDoubler.entryDetails(1);
        assertTrue(paid0 == (expectedResult == 0));
        assertTrue(paid1 == (expectedResult == 1));
    }
}
