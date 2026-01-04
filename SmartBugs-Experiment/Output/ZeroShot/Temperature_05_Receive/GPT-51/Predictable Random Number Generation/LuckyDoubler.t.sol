
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {
    LuckyDoubler lucky;

    function setUp() public {
        lucky = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 depositCount) public {
        vm.assume(blockNumber > 1 && blockNumber < type(uint256).max - 1000);
        vm.assume(depositCount > 1 && depositCount <= 20);

        vm.roll(blockNumber);

        vm.deal(address(this), depositCount * 1 ether + 1 ether);

        uint256[] memory expectedIndexes = new uint256[](depositCount);

        uint256 FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;

        for (uint256 i = 0; i < depositCount; i++) {
            uint256 unpaidLen = i + 1;
            uint256 index;
            if (unpaidLen > 1) {
                uint256 max = unpaidLen;
                uint256 factor = FACTOR * 100 / max;
                uint256 lastBlockNumber = block.number - 1;
                bytes32 bh = vm.load(
                    address(0),
                    bytes32(lastBlockNumber)
                );
                uint256 hashVal = uint256(bh);
                index = (hashVal / factor) % max;
            } else {
                index = 0;
            }
            expectedIndexes[i] = index;

            (bool ok, ) = address(lucky).call{value: 1 ether}("");
            require(ok, "deposit failed");

            vm.roll(block.number + 1);
        }

        uint256 totalEntries;
        {
            (uint256 count, ) = lucky.totalEntries();
            totalEntries = count;
        }

        uint256 unpaidCount = 0;
        for (uint256 i = 0; i < totalEntries; i++) {
            ( , , bool paid, ) = lucky.entryDetails(i);
            if (!paid) {
                unpaidCount++;
            }
        }

        assertGt(unpaidCount, 0);

        uint256 lastUnpaidIndex = unpaidCount - 1;
        uint256 predicted = expectedIndexes[depositCount - 1];
        assertLt(predicted, unpaidCount);
        assertEq(predicted, lastUnpaidIndex);
    }

    receive() external payable {}

    fallback() external payable {}
}
