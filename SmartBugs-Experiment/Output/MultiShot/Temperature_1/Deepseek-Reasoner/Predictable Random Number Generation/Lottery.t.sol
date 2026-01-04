
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {
    Lottery public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Lottery();
        vm.deal(address(this), 100 ether);
        vm.deal(address(_contractUnderTest), 100 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber >= block.number);
        
        vm.roll(blockNumber);
        
        bool expectedWon = (blockNumber % 2) == 0;
        
        uint256 initialBalance = address(this).balance;
        uint256 betAmount = 1 ether;
        
        _contractUnderTest.makeBet{value: betAmount}();
        
        uint256 finalBalance = address(this).balance;
        
        if (expectedWon) {
            assertEq(finalBalance, initialBalance, "Should have won and gotten money back");
        } else {
            assertEq(finalBalance, initialBalance - betAmount, "Should have lost and paid the bet");
        }
    }
}
