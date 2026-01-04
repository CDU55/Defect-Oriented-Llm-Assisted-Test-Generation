
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
        
        vm.deal(address(this), 1 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);
        
        address player = address(this);
        bytes32 bh = blockhash(blockNumber);
        uint timestamp = blockTimestamp;
        bytes32 hash0 = keccak256(abi.encodePacked(bh, player, uint8(0), timestamp));
        uint8 expectedCard = uint8(uint256(hash0) % 52);
        
        vm.expectEmit(address(_contractUnderTest));
        emit BlackJack.Deal(true, expectedCard);

        uint bet = _contractUnderTest.minBet();
        _contractUnderTest.deal{value: bet}();
    }
}
