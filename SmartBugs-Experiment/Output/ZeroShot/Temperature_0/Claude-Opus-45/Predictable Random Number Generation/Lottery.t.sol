
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {

    Lottery private lottery;
    address private attacker;

    function setUp() public {
        lottery = new Lottery();
        attacker = makeAddr("attacker");
        vm.deal(address(lottery), 10 ether);
        vm.deal(attacker, 10 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockNumber > 0);
        vm.assume(blockNumber < type(uint128).max);

        // --- 2. State Configuration ---
        
        vm.roll(blockNumber);
        
        // --- 3. Replication & Assertion ---
        
        // Predict the outcome by replicating the vulnerable logic
        bool expectedWin = (block.number % 2) == 0;
        
        uint256 attackerBalanceBefore = attacker.balance;
        uint256 betAmount = 1 ether;
        
        // Execute the bet as the attacker
        vm.prank(attacker);
        lottery.makeBet{value: betAmount}();
        
        uint256 attackerBalanceAfter = attacker.balance;
        
        // Assert predictability: we can predict exactly whether the attacker wins or loses
        if (expectedWin) {
            // If we predicted a win, attacker should get their bet back (no loss)
            assertEq(attackerBalanceAfter, attackerBalanceBefore, "Predicted win: balance should remain unchanged");
        } else {
            // If we predicted a loss, attacker loses their bet
            assertEq(attackerBalanceAfter, attackerBalanceBefore - betAmount, "Predicted loss: balance should decrease by bet amount");
        }
    }
}
