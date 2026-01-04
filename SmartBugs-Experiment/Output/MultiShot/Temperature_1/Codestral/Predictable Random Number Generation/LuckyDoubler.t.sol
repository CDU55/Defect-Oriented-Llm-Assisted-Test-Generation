
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {LuckyDoubler} from "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {

    LuckyDoubler public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 2 ether);
        _contractUnderTest = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber >= block.number);

        vm.roll(blockNumber);

        uint256 maxValue = 10;
        uint256 expectedRandom = uint256(uint256(blockhash(blockNumber - 1)) / (1157920892373161954235709850086879078532699846656405640394575840079131296399 * 100 / maxValue)) % maxValue;

        vm.deal(address(_contractUnderTest), 1 ether);
        _contractUnderTest.join();

        uint256 actualRandom = _contractUnderTest.rand(maxValue);

        assertEq(actualRandom, expectedRandom, "Randomness should be predictable given block state");
    }
}
