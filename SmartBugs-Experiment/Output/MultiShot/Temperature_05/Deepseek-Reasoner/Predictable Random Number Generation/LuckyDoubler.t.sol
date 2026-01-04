
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
        
        vm.assume(blockNumber >= 1 && blockNumber <= 256);

        vm.deal(address(this), 10 ether);

        vm.roll(blockNumber);
        
        uint256 predictedHash = uint256(blockhash(blockNumber - 1));
        uint256 factor = 1157920892373161954235709850086879078532699846656405640394575840079131296399 * 100 / 2;
        uint256 expectedRandomIndex = (predictedHash / factor) % 2;

        (bool success1,) = address(_contractUnderTest).call{value: 1 ether}("");
        require(success1, "First deposit failed");
        
        uint256 actualRandomIndex;
        
        (bool success2,) = address(_contractUnderTest).call{value: 1 ether}("");
        require(success2, "Second deposit failed");
        
        (,, bool paidEntry0, ) = _contractUnderTest.entryDetails(0);
        (,, bool paidEntry1, ) = _contractUnderTest.entryDetails(1);
        
        if (expectedRandomIndex == 0) {
            assertTrue(paidEntry0, "Entry 0 should be paid when random index is 0");
            assertFalse(paidEntry1, "Entry 1 should not be paid when random index is 0");
            actualRandomIndex = 0;
        } else {
            assertFalse(paidEntry0, "Entry 0 should not be paid when random index is 1");
            assertTrue(paidEntry1, "Entry 1 should be paid when random index is 1");
            actualRandomIndex = 1;
        }
        
        assertEq(actualRandomIndex, expectedRandomIndex, "Random index should be predictable given parent block hash");
    }
}
