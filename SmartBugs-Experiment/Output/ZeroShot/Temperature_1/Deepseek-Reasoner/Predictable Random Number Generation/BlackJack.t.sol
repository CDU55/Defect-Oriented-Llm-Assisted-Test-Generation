
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {

    BlackJack blackJack;

    function setUp() public {
        blackJack = new BlackJack();
        vm.deal(address(this), 10 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp, address player, uint8 cardNumber) public {
        
        blockNumber = bound(blockNumber, 1, 256);
        cardNumber = bound(cardNumber, 0, 52);

        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        uint8 predictedCard = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber), player, cardNumber, blockTimestamp))) % 52);
        uint8 actualCard = this.externalDeal(player, cardNumber);
        assertEq(actualCard, predictedCard);
    }

    function externalDeal(address player, uint8 cardNumber) external view returns (uint8) {
        uint b = block.number;
        uint timestamp = block.timestamp;
        return uint8(uint256(keccak256(abi.encodePacked(blockhash(b), player, cardNumber, timestamp))) % 52);
    }
}
