
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {

    LuckyDoubler public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        _contractUnderTest = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber >= block.number);

        vm.deal(address(this), 10 ether);

        vm.roll(blockNumber);

        uint256 expectedRandom = uint256(blockhash(blockNumber - 1)) / (1157920892373161954235709850086879078532699846656405640394575840079131296399 * 100 / 1);

        vm.startPrank(address(this));
        _contractUnderTest.join{value: 1 ether}();
        vm.stopPrank();

        uint256 actualRandom = _contractUnderTest.rand(1);

        assertEq(actualRandom, expectedRandom, "Randomness should be predictable given block state");
    }
}
