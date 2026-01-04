
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

        uint256 preBalance = address(this).balance;
        bool predictedWin = (block.number % 2) == 0;
        assertTrue(predictedWin, "Setup should ensure an even block number and a win");

        _contractUnderTest.makeBet{value: 1 ether}();

        uint256 postBalance = address(this).balance;

        if (predictedWin) {
            assertEq(
                postBalance,
                preBalance,
                "Balance should remain the same because we can deterministically bet only on winning blocks"
            );
        }
    }
}
