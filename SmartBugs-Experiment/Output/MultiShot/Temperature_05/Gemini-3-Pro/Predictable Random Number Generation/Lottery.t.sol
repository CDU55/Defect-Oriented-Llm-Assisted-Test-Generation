
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {

    Lottery public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Lottery();
    }

    // Allow the test contract to receive ether from the Lottery contract's transfer
    receive() external payable {}

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        // Ensure blockNumber is valid (non-zero)
        vm.assume(blockNumber > 0);

        // --- 2. State Configuration ---
        vm.deal(address(this), 10 ether);
        
        // Manipulate the block number to control the randomness source
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable logic locally
        bool expectedWon = (blockNumber % 2) == 0;
        
        uint256 betAmount = 1 ether;
        uint256 preBalance = address(this).balance;

        // Execute the bet
        _contractUnderTest.makeBet{value: betAmount}();

        uint256 postBalance = address(this).balance;

        // Assert that the outcome matches our prediction based on the block number
        if (expectedWon) {
            // If we win, the contract transfers the bet amount back
            assertEq(postBalance, preBalance, "Randomness should be predictable: Expected Win based on block number");
        } else {
            // If we lose, the contract keeps the bet amount
            assertEq(postBalance, preBalance - betAmount, "Randomness should be predictable: Expected Loss based on block number");
        }
    }
}
