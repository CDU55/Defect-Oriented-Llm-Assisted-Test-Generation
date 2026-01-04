
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {
    LuckyDoubler public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber > block.number + 2);
        vm.assume(blockNumber < type(uint256).max - 10);

        vm.roll(blockNumber - 2);

        vm.deal(address(this), 10 ether);

        vm.roll(blockNumber - 1);
        payable(address(_contractUnderTest)).call{value: 1 ether}("");

        vm.roll(blockNumber);
        payable(address(_contractUnderTest)).call{value: 1 ether}("");

        uint256 FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
        uint256 max = 2;
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = blockNumber - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));
        uint256 expectedRandom = uint256((hashVal / factor)) % max;

        (uint count, ) = _contractUnderTest.totalEntries();
        assertEq(count, 2, "There should be exactly two entries");

        uint256 predictedIndex = expectedRandom;

        (address user0, , , ) = _contractUnderTest.entryDetails(0);
        (address user1, , , ) = _contractUnderTest.entryDetails(1);

        address expectedPaidUser = predictedIndex == 0 ? user0 : user1;

        (uint deposits0, uint payouts0, ) = _contractUnderTest.userStats(user0);
        (uint deposits1, uint payouts1, ) = _contractUnderTest.userStats(user1);

        assertEq(deposits0, 1, "user0 should have 1 deposit");
        assertEq(deposits1, 1, "user1 should have 1 deposit");

        if (expectedPaidUser == user0) {
            assertEq(payouts0, 1, "Predicted winner user0 should have received payout");
            assertEq(payouts1, 0, "Non-winner user1 should not have received payout");
        } else {
            assertEq(payouts1, 1, "Predicted winner user1 should have received payout");
            assertEq(payouts0, 0, "Non-winner user0 should not have received payout");
        }
    }
}
