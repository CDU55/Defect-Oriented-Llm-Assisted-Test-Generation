
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {
    Lottery lottery;

    function setUp() public {
        lottery = new Lottery();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.roll(blockNumber);
        
        uint256 initialBalance = address(this).balance;
        uint256 betAmount = 1 ether;
        
        deal(address(this), betAmount);
        lottery.makeBet{value: betAmount}();
        
        uint256 finalBalance = address(this).balance;
        bool expectedWin = (blockNumber % 2) == 0;
        
        if (expectedWin) {
            assertEq(finalBalance, initialBalance);
        } else {
            assertEq(finalBalance, initialBalance - betAmount);
        }
    }
}
