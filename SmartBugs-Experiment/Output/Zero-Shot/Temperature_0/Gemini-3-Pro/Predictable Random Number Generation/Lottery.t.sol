
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {

    Lottery lottery;

    function setUp() public {
        lottery = new Lottery();
    }

    // Allow the test contract to receive ETH refunds
    receive() external payable {}

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockNumber > 0);

        // --- 2. State Configuration ---
        
        uint256 betAmount = 1 ether;
        vm.deal(address(this), betAmount);

        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable logic locally inside the test.
        bool expectedWin = (blockNumber % 2) == 0;
                
        uint256 balanceBefore = address(this).balance;

        // Call the contract method.
        lottery.makeBet{value: betAmount}();

        uint256 balanceAfter = address(this).balance;

        // Prove that the contract's "random" value matches our calculated expectation.
        if (expectedWin) {
            // If the block number is even, we predict a win, so the contract refunds the bet.
            // Balance should remain the same (minus gas, but gas is 0 in default foundry tests unless configured otherwise).
            assertEq(balanceAfter, balanceBefore, "Prediction failed: Expected to win and get refund");
        } else {
            // If the block number is odd, we predict a loss.
            // Balance should decrease by the bet amount.
            assertEq(balanceAfter, balanceBefore - betAmount, "Prediction failed: Expected to lose bet amount");
        }
    }
}
