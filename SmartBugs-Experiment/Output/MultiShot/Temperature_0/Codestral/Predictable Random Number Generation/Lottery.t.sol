
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {

    Lottery public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new Lottery();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber >= block.number);

        vm.deal(address(this), 1 ether);

        vm.roll(blockNumber);

        bool expectedWon = (blockNumber % 2) == 0;

        vm.prank(address(this));
        _contractUnderTest.makeBet{value: 1 ether}();

        bool actualWon = _contractUnderTest.bets(0).won;

        assertEq(actualWon, expectedWon, "Randomness should be predictable given block number");
    }
}
