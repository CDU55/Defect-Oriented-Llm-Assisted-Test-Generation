
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {

    Lottery private lottery;
    address private attacker;

    function setUp() public {
        // Fund the lottery contract so it can pay out winnings
        lottery = new Lottery();
        vm.deal(address(lottery), 10 ether);
        
        attacker = address(0x1234);
        vm.deal(attacker, 1 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        // Ensure block number is reasonable and even (winning condition)
        vm.assume(blockNumber > 0);
        vm.assume(blockNumber < type(uint256).max - 1000);
        // Force an even block number to guarantee a win
        blockNumber = blockNumber - (blockNumber % 2);

        // --- 2. State Configuration ---
        
        // Manipulate block number to the attacker's advantage
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Predict the outcome locally - we know we will win because block.number is even
        bool predictedWin = (block.number % 2) == 0;
        
        // Verify our prediction matches the manipulated state
        assertTrue(predictedWin, "Predicted outcome should be a win");
        
        // Record attacker's balance before the bet
        uint256 attackerBalanceBefore = attacker.balance;
        uint256 betAmount = 0.1 ether;
        
        // Execute the bet as the attacker
        vm.prank(attacker);
        lottery.makeBet{value: betAmount}();
        
        // Assert predictability - attacker should have their bet returned (win condition)
        uint256 attackerBalanceAfter = attacker.balance;
        
        // If we won, balance should be the same as before (bet returned)
        // If we lost, balance should be reduced by betAmount
        assertEq(
            attackerBalanceAfter, 
            attackerBalanceBefore, 
            "Attacker should have won and received their bet back"
        );
    }
}
