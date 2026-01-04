
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {

    LuckyDoubler public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockNumber >= block.number);
        

        // --- 2. State Configuration ---
        
        vm.deal(address(this), 100 ether);

        vm.roll(blockNumber);

        payable(address(_contractUnderTest)).transfer(1 ether);
        
        vm.roll(block.number + 1);

        // --- 3. Replication & Assertion ---
        
        uint256 targetBlock = block.number;
        uint256 lastBlockNumber = targetBlock - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));

        uint max = 2;
        uint256 factor = 1157920892373161954235709850086879078532699846656405640394575840079131296399 * 100 / max;
        uint256 expectedRandom = uint256((hashVal / factor)) % max;

        payable(address(_contractUnderTest)).transfer(1 ether);

        ( , , bool paid0, ) = _contractUnderTest.entryDetails(0);
        ( , , bool paid1, ) = _contractUnderTest.entryDetails(1);

        if (expectedRandom == 0) {
            assertTrue(paid0);
            assertFalse(paid1);
        } else {
            assertFalse(paid0);
            assertTrue(paid1);
        }
    }
}
