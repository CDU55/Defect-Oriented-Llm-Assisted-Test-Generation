
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {

    BlackJack public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        _contractUnderTest = new BlackJack();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        vm.assume(blockNumber >= block.number);
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(type(uint256).max - blockNumber >= blockTimestamp);

        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        uint256 expectedCard = uint256(keccak256(abi.encodePacked(blockhash(blockNumber), address(this), 0, blockTimestamp))) % 52;

        _contractUnderTest.deal{value: 0.1 ether}();

        uint8 actualCard = _contractUnderTest.getPlayerCard(0);

        assertEq(uint256(actualCard), expectedCard, "Randomness should be predictable given block state");
    }
}
