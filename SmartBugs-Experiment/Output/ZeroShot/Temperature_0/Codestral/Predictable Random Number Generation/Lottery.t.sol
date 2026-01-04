
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/Lottery.sol";

contract TestWeakRandomnessLottery is Test {

    Lottery public lottery;

    function setUp() public {
        lottery = new Lottery();
    }

    function test_highlightPredictableRandomValue(uint blockNumber) public {
        // --- 1. Constraints ---
        blockNumber = blockNumber % 2 == 0 ? blockNumber : blockNumber + 1;

        // --- 2. State Configuration ---
        vm.deal(address(this), 1 ether);

        // --- 3. Manipulate Block Environment ---
        vm.roll(blockNumber);

        // --- 4. Replication & Assertion ---
        bool expectedWon = (blockNumber % 2) == 0;

        vm.prank(address(this));
        lottery.makeBet{value: 1 ether}();

        Bet[] memory bets = lottery.getBets();
        assertEq(bets[0].won, expectedWon, "Randomness is predictable");
    }
}
