
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {

    Lottery lottery;

    function setUp() public {
        lottery = new Lottery();
    }

    // Needed to receive ETH via transfer()
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
        bool expectedWon = (blockNumber % 2) == 0;
        
        uint256 initialBalance = address(this).balance;
                
        // Call the contract method.
        lottery.makeBet{value: betAmount}();

        // Prove that the contract's "random" value matches our calculated expectation.
        if (expectedWon) {
            // If we predicted a win, the contract transfers the value back.
            // Balance should remain unchanged (minus gas, but Foundry tests usually ignore gas unless specified).
            assertEq(address(this).balance, initialBalance, "Predicted a win, but funds were not returned");
            assertEq(address(lottery).balance, 0, "Lottery should be empty after a win");
        } else {
            // If we predicted a loss, the contract keeps the value.
            assertEq(address(this).balance, initialBalance - betAmount, "Predicted a loss, but funds were returned");
            assertEq(address(lottery).balance, betAmount, "Lottery should hold the bet after a loss");
        }
    }

    fallback() external payable {}
}
