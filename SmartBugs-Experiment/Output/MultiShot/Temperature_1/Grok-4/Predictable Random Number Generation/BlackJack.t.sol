
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {

    BlackJack public blackJack;

    function setUp() public {
        blackJack = new BlackJack();
        vm.deal(address(blackJack), 1000 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        vm.assume(blockTimestamp >= block.timestamp);
        
        vm.assume(blockNumber >= block.number);
        
        vm.deal(address(this), 100 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);
        
        address player = address(this);
        uint256 b = blockNumber;
        uint256 timestamp = blockTimestamp;
        bytes32 bh = blockhash(blockNumber);

        uint8 expectedPlayerCard0 = uint8(uint256(keccak256(abi.encodePacked(bh, player, uint8(0), timestamp))) % 52);
        uint8 expectedHouseCard0 = uint8(uint256(keccak256(abi.encodePacked(bh, player, uint8(1), timestamp))) % 52);
        uint8 expectedPlayerCard1 = uint8(uint256(keccak256(abi.encodePacked(bh, player, uint8(2), timestamp))) % 52);

        vm.expectEmit(true, true, true, true);
        emit BlackJack.Deal(true, expectedPlayerCard0);
        vm.expectEmit(true, true, true, true);
        emit BlackJack.Deal(false, expectedHouseCard0);
        vm.expectEmit(true, true, true, true);
        emit BlackJack.Deal(true, expectedPlayerCard1);

        blackJack.deal{value: 0.05 ether}();
    }
}
