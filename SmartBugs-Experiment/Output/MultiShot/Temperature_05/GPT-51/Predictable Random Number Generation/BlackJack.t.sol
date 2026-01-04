
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack, Deck} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {
    BlackJack public blackjack;

    function setUp() public {
        blackjack = new BlackJack();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber > 0);

        vm.deal(address(this), 10 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        address player = address(this);
        uint8 cardNumber = 0;

        uint8 expected = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number),
                        player,
                        cardNumber,
                        block.timestamp
                    )
                )
            ) % 52
        );

        uint256 betAmount = blackjack.minBet();
        blackjack.deal{value: betAmount}();

        uint8 actual = blackjack.getPlayerCard(0);

        assertEq(actual, expected, "Random card should be predictable from block state");
    }
}
