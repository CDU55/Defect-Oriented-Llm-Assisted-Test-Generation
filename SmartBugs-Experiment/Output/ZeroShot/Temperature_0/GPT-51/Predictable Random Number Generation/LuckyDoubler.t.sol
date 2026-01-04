
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {
    LuckyDoubler lucky;

    address player1 = address(0x1);
    address player2 = address(0x2);

    function setUp() public {
        lucky = new LuckyDoubler();
        vm.deal(player1, 10 ether);
        vm.deal(player2, 10 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber > 1 && blockNumber < type(uint256).max - 10);

        vm.roll(blockNumber - 1);
        vm.prank(player1);
        (bool s1, ) = address(lucky).call{value: 1 ether}("");
        require(s1, "first join failed");

        vm.roll(blockNumber);
        vm.prank(player2);
        (bool s2, ) = address(lucky).call{value: 1 ether}("");
        require(s2, "second join failed");

        uint256 max = 2;
        uint256 FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = blockNumber - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));
        uint256 expectedIndex = (hashVal / factor) % max;

        if (expectedIndex == 0) {
            (uint deposits1, uint payouts1, ) = lucky.userStats(player1);
            assertEq(deposits1, 1, "player1 deposits mismatch");
            assertEq(payouts1, 1, "player1 should have been paid predictably");
        } else {
            (uint deposits2, uint payouts2, ) = lucky.userStats(player2);
            assertEq(deposits2, 1, "player2 deposits mismatch");
            assertEq(payouts2, 1, "player2 should have been paid predictably");
        }
    }
}
