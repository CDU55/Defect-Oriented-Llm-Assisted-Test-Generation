
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {

    Lottery lottery;

    function setUp() public {
        lottery = new Lottery();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockNumber > 0);
        

        // --- 2. State Configuration ---
        
        address player = address(1234);
        vm.deal(player, 1 ether);

        
        vm.roll(blockNumber);
        

        // --- 3. Replication & Assertion ---
        
        bool expectedWon = (blockNumber % 2) == 0;
                
        vm.prank(player);
        uint256 betAmount = 0.1 ether;
        lottery.makeBet{value: betAmount}();

        
        vm.expectEmit(true, true, true, true, address(lottery));
        emit Lottery.GetBet(betAmount, blockNumber, expectedWon);
        lottery.getBets();
        
    }
}
