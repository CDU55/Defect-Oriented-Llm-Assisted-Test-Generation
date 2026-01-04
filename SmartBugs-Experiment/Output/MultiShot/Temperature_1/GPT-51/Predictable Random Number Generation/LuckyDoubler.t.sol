
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {
    LuckyDoubler public lucky;

    receive() external payable {}

    function setUp() public {
        lucky = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber > block.number + 1);
        vm.assume(blockNumber < type(uint256).max - 10);

        vm.deal(address(this), 100 ether);

        vm.roll(blockNumber);

        uint256 max = 2;
        uint256 FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));
        uint256 expectedRandom = uint256((uint256(hashVal) / factor)) % max;

        address user1 = address(0x1);
        address user2 = address(0x2);

        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        vm.prank(user1);
        (bool s1,) = address(lucky).call{value: 1 ether}("");
        require(s1, "send 1 failed");

        vm.roll(block.number + 1);

        vm.prank(user2);
        (bool s2,) = address(lucky).call{value: 1 ether}("");
        require(s2, "send 2 failed");

        uint256 indexPaid;
        (address u0,, bool paid0,) = lucky.entryDetails(0);
        (address u1,, bool paid1,) = lucky.entryDetails(1);

        if (paid0) {
            indexPaid = 0;
        } else if (paid1) {
            indexPaid = 1;
        } else {
            revert("no entry paid");
        }

        assertEq(indexPaid, expectedRandom, "Random payout index should be predictable from blockhash");
        if (indexPaid == 0) {
            assertEq(u0, user1, "Entry 0 should belong to user1");
        } else {
            assertEq(u1, user2, "Entry 1 should belong to user2");
        }
    }
}
