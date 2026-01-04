
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {
    Lottery lottery;
    address player = address(0x1234);
    
    function setUp() public {
        lottery = new Lottery();
        vm.deal(player, 10 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        vm.roll(blockNumber);
        
        bool expectedWin = (blockNumber % 2) == 0;
        uint256 playerBalanceBefore = player.balance;
        uint256 betAmount = 1 ether;
        
        vm.prank(player);
        lottery.makeBet{value: betAmount}();
        
        uint256 playerBalanceAfter = player.balance;
        
        if (expectedWin) {
            assertEq(playerBalanceAfter, playerBalanceBefore);
        } else {
            assertEq(playerBalanceAfter, playerBalanceBefore - betAmount);
        }
    }
}
