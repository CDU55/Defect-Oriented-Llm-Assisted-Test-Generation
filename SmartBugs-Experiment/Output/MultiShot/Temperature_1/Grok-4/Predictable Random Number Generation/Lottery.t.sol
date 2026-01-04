
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
        
        // --- 1. Constraints ---
        vm.assume(blockNumber >= block.number);
        
        // --- 2. State Configuration ---
        
        vm.deal(address(this), 100 ether);
        
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        bool expectedWon = (blockNumber % 2) == 0;
        
        uint256 betValue = 1 ether;
        uint256 initialBalance = address(this).balance;
        _contractUnderTest.makeBet{value: betValue}();
        uint256 finalBalance = address(this).balance;
        
        if (expectedWon) {
            assertEq(finalBalance, initialBalance, "Predicted win, balance should remain the same");
        } else {
            assertEq(finalBalance, initialBalance - betValue, "Predicted loss, balance should decrease by bet value");
        }
    }
}
