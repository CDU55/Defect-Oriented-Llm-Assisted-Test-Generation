
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {
    BlackJack public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new BlackJack();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber <= block.number + 256);

        vm.deal(address(this), 100 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        address player = address(this);
        uint8 expectedCard0 = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber), player, uint8(0), blockTimestamp))) % 52);
        uint8 expectedCard1 = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber), player, uint8(1), blockTimestamp))) % 52);
        uint8 expectedCard2 = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber), player, uint8(2), blockTimestamp))) % 52);

        _contractUnderTest.deal{value: 0.05 ether}();

        uint8 actualCard0 = _contractUnderTest.getPlayerCard(0);
        uint8 actualCard1 = _contractUnderTest.getHouseCard(0);
        uint8 actualCard2 = _contractUnderTest.getPlayerCard(1);

        assertEq(actualCard0, expectedCard0, "Card 0 should be predictable given block state");
        assertEq(actualCard1, expectedCard1, "Card 1 should be predictable given block state");
        assertEq(actualCard2, expectedCard2, "Card 2 should be predictable given block state");
    }
}
