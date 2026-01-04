
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
        
        // --- 1. Constraints ---
        
        
        

        // --- 2. State Configuration ---
        
        uint256 betAmount = 1 ether;
        vm.deal(address(this), betAmount);

        
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        bool expectedWon = (blockNumber % 2) == 0;
                
        
        lottery.makeBet{value: betAmount}();

        
        if (expectedWon) {
            assertEq(address(lottery).balance, 0);
        } else {
            assertEq(address(lottery).balance, betAmount);
        }
    }
}
