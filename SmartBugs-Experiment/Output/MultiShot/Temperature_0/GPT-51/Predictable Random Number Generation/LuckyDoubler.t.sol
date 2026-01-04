
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {
    LuckyDoubler public lucky;

    function setUp() public {
        lucky = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber > block.number + 1);
        vm.assume(blockNumber < type(uint256).max - 10);

        vm.deal(address(this), 10 ether);

        vm.roll(blockNumber);

        uint256 FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
        uint256 max = 1;
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));
        uint256 expectedRandom = uint256((uint256(hashVal) / factor)) % max;

        assertEq(expectedRandom, 0, "For max=1, predictable random must be 0");

        (bool success, ) = address(lucky).call{value: 1 ether}("");
        require(success, "join via receive failed");
    }
}
