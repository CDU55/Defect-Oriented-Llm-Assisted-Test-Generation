
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {

    Lottery public _contractUnderTest;
    address public attacker;

    event GetBet(uint betAmount, uint blockNumber, bool won);

    function setUp() public {
        _contractUnderTest = new Lottery();
        attacker = makeAddr("attacker");
        vm.deal(address(_contractUnderTest), 10 ether);
        vm.deal(attacker, 10 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockNumber >= 1);
        vm.assume(blockNumber < type(uint256).max);

        // --- 2. State Configuration ---
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable logic locally inside the test.
        // The contract determines win/loss based on whether block.number is even
        bool expectedWon = (block.number % 2) == 0;
        
        // Record attacker balance before bet
        uint256 attackerBalanceBefore = attacker.balance;
        uint256 betAmount = 1 ether;
        
        // Execute the bet as the attacker
        vm.prank(attacker);
        _contractUnderTest.makeBet{value: betAmount}();
        
        uint256 attackerBalanceAfter = attacker.balance;
        
        // Assert predictability: if we predicted a win, attacker should get money back
        // if we predicted a loss, attacker loses the bet amount
        if (expectedWon) {
            // On win, the contract transfers the bet amount back
            assertEq(
                attackerBalanceAfter, 
                attackerBalanceBefore - betAmount + betAmount, 
                "On predicted win, attacker should receive bet back"
            );
            assertEq(
                attackerBalanceAfter, 
                attackerBalanceBefore, 
                "Balance should be unchanged on win"
            );
        } else {
            // On loss, the attacker loses the bet
            assertEq(
                attackerBalanceAfter, 
                attackerBalanceBefore - betAmount, 
                "On predicted loss, attacker should lose bet amount"
            );
        }
    }
}
