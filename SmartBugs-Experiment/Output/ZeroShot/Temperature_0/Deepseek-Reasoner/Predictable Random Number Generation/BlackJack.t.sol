
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {
    BlackJack public blackjack;

    function setUp() public {
        blackjack = new BlackJack();
        vm.deal(address(this), 10 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        vm.assume(blockTimestamp > 0);
        vm.assume(blockNumber > 0);

        uint256 betAmount = 0.05 ether;
        address player = address(this);

        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        bytes32 currentBlockhash = blockhash(blockNumber);
        uint8 expectedCard0 = uint8(uint256(keccak256(abi.encodePacked(currentBlockhash, player, uint8(0), blockTimestamp))) % 52);
        uint8 expectedCard1 = uint8(uint256(keccak256(abi.encodePacked(currentBlockhash, player, uint8(1), blockTimestamp))) % 52);
        uint8 expectedCard2 = uint8(uint256(keccak256(abi.encodePacked(currentBlockhash, player, uint8(2), blockTimestamp))) % 52);

        blackjack.deal{value: betAmount}();

        assertEq(blackjack.getPlayerCard(0), expectedCard0);
        assertEq(blackjack.getHouseCard(0), expectedCard1);
        assertEq(blackjack.getPlayerCard(1), expectedCard2);
    }
}
