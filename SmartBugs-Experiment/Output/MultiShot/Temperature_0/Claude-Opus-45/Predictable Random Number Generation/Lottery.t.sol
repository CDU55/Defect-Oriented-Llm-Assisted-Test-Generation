
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {

    Lottery public _contractUnderTest;
    address public attacker;

    function setUp() public {
        vm.deal(address(this), 100 ether);
        _contractUnderTest = new Lottery();
        vm.deal(address(_contractUnderTest), 10 ether);
        attacker = address(0x1234);
        vm.deal(attacker, 10 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber < type(uint256).max - 1000);

        // --- 2. State Configuration ---
        vm.deal(attacker, 10 ether);
        
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable logic locally inside the test.
        // The contract determines win/loss based on block.number % 2 == 0
        bool expectedWin = (block.number % 2) == 0;
        
        uint256 attackerBalanceBefore = attacker.balance;
        uint256 betAmount = 1 ether;
        
        // Execute the bet as the attacker
        vm.prank(attacker);
        _contractUnderTest.makeBet{value: betAmount}();
        
        uint256 attackerBalanceAfter = attacker.balance;
        
        // Assert predictability: if we predicted a win, balance should be unchanged (got money back)
        // If we predicted a loss, balance should decrease by betAmount
        if (expectedWin) {
            assertEq(attackerBalanceAfter, attackerBalanceBefore - betAmount + betAmount, "Should win and get bet back when block.number is even");
        } else {
            assertEq(attackerBalanceAfter, attackerBalanceBefore - betAmount, "Should lose bet when block.number is odd");
        }
    }

    receive() external payable {}
}
