
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

        vm.deal(address(this), 10 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        address player = address(this);
        uint256 bet = blackjack.minBet();

        uint8 expectedCard0 = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number),
                        player,
                        uint8(0),
                        block.timestamp
                    )
                )
            ) % 52
        );
        uint8 expectedCard1 = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number),
                        player,
                        uint8(1),
                        block.timestamp
                    )
                )
            ) % 52
        );
        uint8 expectedCard2 = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number),
                        player,
                        uint8(2),
                        block.timestamp
                    )
                )
            ) % 52
        );

        blackjack.deal{value: bet}();

        uint8 actualCard0 = blackjack.getPlayerCard(0);
        uint8 actualCard1 = blackjack.getHouseCard(0);
        uint8 actualCard2 = blackjack.getPlayerCard(1);

        assertEq(actualCard0, expectedCard0, "First player card should be predictable");
        assertEq(actualCard1, expectedCard1, "First house card should be predictable");
        assertEq(actualCard2, expectedCard2, "Second player card should be predictable");
    }
}
