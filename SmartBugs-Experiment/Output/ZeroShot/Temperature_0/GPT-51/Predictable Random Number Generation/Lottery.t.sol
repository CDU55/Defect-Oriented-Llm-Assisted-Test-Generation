
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
        uint256 balanceBefore = attacker.balance;
        lottery.makeBet{value: 1 ether}();
        uint256 balanceAfter = attacker.balance;
        vm.stopPrank();

        if (expectedWon) {
            assertEq(
                balanceAfter,
                balanceBefore,
                "Attacker should get their bet back when block number is even"
            );
        } else {
            assertEq(
                balanceAfter,
                balanceBefore - 1 ether,
                "Attacker should lose their bet when block number is odd"
            );
        }
    }
}
