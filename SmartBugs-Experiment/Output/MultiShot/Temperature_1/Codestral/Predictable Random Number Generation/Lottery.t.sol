
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
        // --- 1. Constraints ---
        vm.assume(blockNumber >= block.number);

        // --- 2. State Configuration ---
        vm.deal(address(this), 1 ether);

        // --- 3. Manipulate Block Environment ---
        vm.roll(blockNumber);

        // --- 4. Replication & Assertion ---
        bool expectedWon = (blockNumber % 2) == 0;

        // Execute
        _contractUnderTest.makeBet{value: 1 ether}();

        // Assert
        Bet[] memory bets = _contractUnderTest.getBets();
        Bet memory lastBet = bets[bets.length - 1];
        assertEq(lastBet.won, expectedWon, "Randomness should be predictable given block number");
    }
}
