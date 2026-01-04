
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

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 timestamp) public {
        vm.assume(blockNumber >= block.number);
        vm.assume(timestamp >= block.timestamp);

        vm.roll(blockNumber);
        vm.warp(timestamp);

        vm.deal(address(this), 1 ether);
        _contractUnderTest.deal{value: 1 ether}();

        uint8 expectedCard = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber), address(this), 0, timestamp))) % 52);
        uint8 actualCard = _contractUnderTest.getPlayerCard(0);

        assertEq(actualCard, expectedCard, "Card should be predictable given block state");
    }
}
