
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {

    Lottery private lottery;
    address private attacker;

    function setUp() public {
        // Deploy lottery contract with some initial funds
        lottery = new Lottery();
        // Fund the lottery so it can pay out winnings
        vm.deal(address(lottery), 10 ether);
        
        // Setup attacker address
        attacker = address(0x1234);
        vm.deal(attacker, 1 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        // Constrain block number to reasonable values
        vm.assume(blockNumber > 0);
        vm.assume(blockNumber < type(uint128).max);

        // --- 2. State Configuration ---
        
        // Manipulate block environment - set the block number
        vm.roll(blockNumber);
        
        // --- 3. Replication & Assertion ---
        
        // Predict the outcome by replicating the vulnerable logic
        // The contract uses: bool won = (block.number % 2) == 0;
        bool predictedWin = (block.number % 2) == 0;
        
        // Record attacker balance before the bet
        uint256 attackerBalanceBefore = attacker.balance;
        uint256 betAmount = 0.1 ether;
        
        // Execute the bet as the attacker
        vm.prank(attacker);
        lottery.makeBet{value: betAmount}();
        
        // Get attacker balance after the bet
        uint256 attackerBalanceAfter = attacker.balance;
        
        // Assert predictability - verify our prediction matches the actual outcome
        if (predictedWin) {
            // If we predicted a win, attacker should get their bet back
            // Balance should be: before - betAmount + betAmount = before
            assertEq(
                attackerBalanceAfter, 
                attackerBalanceBefore, 
                "Predicted win but balance doesn't match expected winning outcome"
            );
        } else {
            // If we predicted a loss, attacker loses their bet
            // Balance should be: before - betAmount
            assertEq(
                attackerBalanceAfter, 
                attackerBalanceBefore - betAmount, 
                "Predicted loss but balance doesn't match expected losing outcome"
            );
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
