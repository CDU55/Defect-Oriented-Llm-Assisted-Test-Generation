
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {
    BlackJack public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new BlackJack();
        vm.deal(address(this), 100 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 betAmount = 0.05 ether;
        
        address player = address(this);
        uint8 cardNumber = 0;
        bytes32 currentBlockhash = blockhash(blockNumber);
        
        uint8 expectedCard = uint8(uint256(keccak256(abi.encodePacked(currentBlockhash, player, cardNumber, blockTimestamp))) % 52);

        _contractUnderTest.deal{value: betAmount}();
        uint8 actualCard = _contractUnderTest.getPlayerCard(0);
        
        assertEq(actualCard, expectedCard, "Randomness should be predictable given block state");
    }
}
