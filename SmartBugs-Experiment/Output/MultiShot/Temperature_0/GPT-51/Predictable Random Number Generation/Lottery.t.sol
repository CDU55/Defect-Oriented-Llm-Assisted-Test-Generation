
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {Lottery} from "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {
    Lottery public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Lottery();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber < type(uint256).max);

        vm.deal(address(this), 100 ether);

        vm.roll(blockNumber);

        bool expectedWon = (block.number % 2) == 0;

        uint256 betAmount = 1 ether;
        uint256 balanceBefore = address(this).balance;

        _contractUnderTest.makeBet{value: betAmount}();

        uint256 balanceAfter = address(this).balance;

        if (expectedWon) {
            assertEq(
                balanceAfter,
                balanceBefore,
                "When block.number is even, bet should be refunded (predictable win)"
            );
        } else {
            assertEq(
                balanceAfter,
                balanceBefore - betAmount,
                "When block.number is odd, bet should be lost (predictable loss)"
            );
        }
    }
}
