
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {
    LuckyDoubler public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockHashValue) public {
        
        vm.assume(blockNumber >= 1);
        vm.assume(blockNumber <= block.number + 256);
        vm.assume(blockHashValue <= type(uint256).max);

        vm.deal(address(this), 2 ether);

        vm.roll(blockNumber);
        vm.mockBlockHash(blockNumber - 1, bytes32(blockHashValue));

        uint256 max = 2;
        uint256 factor = 1157920892373161954235709850086879078532699846656405640394575840079131296399 * 100 / max;
        uint256 expectedRandom = (blockHashValue / factor) % max;

        _contractUnderTest = new LuckyDoubler();
        (bool success1,) = address(_contractUnderTest).call{value: 1 ether}("");
        require(success1, "First deposit failed");

        (bool success2,) = address(_contractUnderTest).call{value: 1 ether}("");
        require(success2, "Second deposit failed");

        uint256 entriesCount;
        (entriesCount,) = _contractUnderTest.totalEntries();
        
        uint256 paidEntryIndex = expectedRandom;
        if (paidEntryIndex == 0) {
            (, , bool paid0, ) = _contractUnderTest.entryDetails(0);
            assertTrue(paid0, "Entry 0 should be paid based on predictable random");
            (, , bool paid1, ) = _contractUnderTest.entryDetails(1);
            assertTrue(!paid1, "Entry 1 should not be paid based on predictable random");
        } else {
            (, , bool paid0, ) = _contractUnderTest.entryDetails(0);
            assertTrue(!paid0, "Entry 0 should not be paid based on predictable random");
            (, , bool paid1, ) = _contractUnderTest.entryDetails(1);
            assertTrue(paid1, "Entry 1 should be paid based on predictable random");
        }
    }
}
