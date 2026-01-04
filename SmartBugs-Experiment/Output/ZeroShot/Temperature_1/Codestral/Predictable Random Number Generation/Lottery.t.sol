
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {

    Lottery public lottery;

    function setUp() public {
        lottery = new Lottery();
    }

    function test_highlightPredictableRandomValue(uint targetBlockNumber) public {
        // --- 1. Constraints ---
        targetBlockNumber = targetBlockNumber % 2 == 0 ? targetBlockNumber : targetBlockNumber + 1;

        // --- 2. State Configuration ---
        uint betAmount = 1 ether;
        deal(address(this), betAmount);

        // --- 3. Replication & Assertion ---
        bool expectedResult = targetBlockNumber % 2 == 0;

        vm.roll(targetBlockNumber);

        uint initialBalance = address(this).balance;
        lottery.makeBet{value: betAmount}();

        bool actualResult = lottery.getBets()[0].won;

        assertEq(actualResult, expectedResult, "Randomness is predictable");
    }
}
