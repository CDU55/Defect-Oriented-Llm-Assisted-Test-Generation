
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
        vm.assume(blockNumber % 2 == 0);

        vm.deal(address(this), 1 ether);
        vm.roll(blockNumber);

        bool expectedWon = (block.number % 2) == 0;
        assertTrue(expectedWon, "Precondition: block.number must be even to win");

        uint256 balanceBefore = address(this).balance;

        _contractUnderTest.makeBet{value: 1 ether}();

        uint256 balanceAfter = address(this).balance;

        assertEq(
            balanceAfter,
            balanceBefore,
            "Given control over block.number, the outcome of makeBet is fully predictable"
        );
    }
}
