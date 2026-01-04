
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {
    Lottery lottery;
    address attacker = address(0xBEEF);

    function setUp() public {
        lottery = new Lottery();
        vm.deal(attacker, 10 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber > block.number);
        vm.assume(blockNumber < type(uint256).max - 1000);

        vm.roll(blockNumber);

        bool expectedWon = (blockNumber % 2) == 0;

        vm.startPrank(attacker);
        uint256 attackerBalanceBefore = attacker.balance;
        uint256 betAmount = 1 ether;

        lottery.makeBet{value: betAmount}();

        uint256 attackerBalanceAfter = attacker.balance;
        vm.stopPrank();

        if (expectedWon) {
            assertEq(
                attackerBalanceAfter,
                attackerBalanceBefore,
                "Attacker should receive refund when block number is even"
            );
        } else {
            assertEq(
                attackerBalanceAfter,
                attackerBalanceBefore - betAmount,
                "Attacker should lose bet when block number is odd"
            );
        }
    }
}
