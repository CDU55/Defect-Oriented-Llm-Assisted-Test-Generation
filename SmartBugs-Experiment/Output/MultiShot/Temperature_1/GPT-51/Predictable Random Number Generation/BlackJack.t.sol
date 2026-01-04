
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
        vm.deal(address(this), 10 ether);

        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber > 0);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        address player = address(this);
        uint256 bet = blackjack.minBet();

        bytes32 bh = blockhash(block.number);
        uint8 expectedPlayerCard0 = uint8(
            uint256(keccak256(abi.encodePacked(bh, player, uint8(0), block.timestamp))) % 52
        );
        uint8 expectedHouseCard0 = uint8(
            uint256(keccak256(abi.encodePacked(bh, player, uint8(1), block.timestamp))) % 52
        );
        uint8 expectedPlayerCard1 = uint8(
            uint256(keccak256(abi.encodePacked(bh, player, uint8(2), block.timestamp))) % 52
        );

        blackjack.deal{value: bet}();

        uint8 actualPlayerCard0 = blackjack.getPlayerCard(0);
        uint8 actualHouseCard0 = blackjack.getHouseCard(0);
        uint8 actualPlayerCard1 = blackjack.getPlayerCard(1);

        assertEq(actualPlayerCard0, expectedPlayerCard0, "player card[0] should be predictable");
        assertEq(actualHouseCard0, expectedHouseCard0, "house card[0] should be predictable");
        assertEq(actualPlayerCard1, expectedPlayerCard1, "player card[1] should be predictable");
    }
}
