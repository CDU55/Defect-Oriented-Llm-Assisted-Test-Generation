
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
        vm.roll(blockNumber);

        address user = makeAddr("user");
        vm.deal(user, 100 ether);
        vm.prank(user);

        uint256 betAmount = 1 ether;
        uint256 balanceBefore = user.balance;
        _contractUnderTest.makeBet{value: betAmount}();
        uint256 balanceAfter = user.balance;

        bool expectedWon = (blockNumber % 2) == 0;

        if (expectedWon) {
            assertEq(balanceAfter, balanceBefore, "User should not lose money when winning");
        } else {
            assertEq(balanceAfter, balanceBefore - betAmount, "User should lose the bet amount when losing");
        }
    }
}
