
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {
    BlackJack public _contractUnderTest;

    function setUp() public {
        _contractUnderTest = new BlackJack();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(type(uint256).max - blockNumber >= blockTimestamp);

        vm.deal(address(this), 100 ether);
        
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint8 expectedFirstCard = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber), address(this), uint8(0), blockTimestamp))) % 52);
        
        _contractUnderTest.deal{value: 0.05 ether}();
        uint8 actualFirstCard = _contractUnderTest.getPlayerCard(0);
        
        assertEq(actualFirstCard, expectedFirstCard, "Randomness should be predictable given block state");
    }
}
