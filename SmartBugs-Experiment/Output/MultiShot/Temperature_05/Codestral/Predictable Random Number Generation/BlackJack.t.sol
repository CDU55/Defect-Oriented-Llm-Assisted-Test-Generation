
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

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 player = uint256(uint160(address(this)));
        uint256 cardNumber = 0;

        bytes32 blockHash = blockhash(blockNumber);
        uint256 expectedRandom = uint256(keccak256(abi.encodePacked(blockHash, player, cardNumber, blockTimestamp))) % 52;

        vm.startPrank(address(this));
        _contractUnderTest.deal{value: 1 ether}();

        uint8 actualRandom = _contractUnderTest.getPlayerCard(0);
        assertEq(actualRandom, uint8(expectedRandom), "Randomness should be predictable given block state");
    }
}
