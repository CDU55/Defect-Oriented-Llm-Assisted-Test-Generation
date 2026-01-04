
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {

    Lottery public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Lottery();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        vm.assume(blockNumber >= block.number);
        
        vm.deal(address(this), 100 ether);

        vm.roll(blockNumber);
        
        bool expectedWon = (blockNumber % 2) == 0;
        
        uint256 initialBalance = address(this).balance;
        
        _contractUnderTest.makeBet{value: 1 ether}();
        
        uint256 finalBalance = address(this).balance;
        
        bool actualWon = (finalBalance == initialBalance);
        
        assertEq(actualWon, expectedWon, "Won status should be predictable based on block number");
    }
}
