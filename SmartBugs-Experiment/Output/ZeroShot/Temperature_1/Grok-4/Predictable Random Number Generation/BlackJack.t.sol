
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {BlackJack} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {

    BlackJack bj;

    function setUp() public {
        bj = new BlackJack();
        payable(address(bj)).transfer(10 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        
        vm.assume(blockNumber > 0);
        vm.assume(blockTimestamp > 0);
        
        address player = makeAddr("player");
        vm.deal(player, 1 ether);

        vm.roll(blockNumber);
        vm.warp(blockTimestamp);
        
        bytes32 bhash = blockhash(blockNumber);
        uint8 predicted0 = uint8(uint256(keccak256(abi.encodePacked(bhash, player, uint8(0), blockTimestamp))) % 52);
        uint8 predicted1 = uint8(uint256(keccak256(abi.encodePacked(bhash, player, uint8(1), blockTimestamp))) % 52);
        uint8 predicted2 = uint8(uint256(keccak256(abi.encodePacked(bhash, player, uint8(2), blockTimestamp))) % 52);
        
        vm.expectEmit(true, true, true, true, address(bj));
        emit BlackJack.Deal(true, predicted0);
        vm.expectEmit(true, true, true, true, address(bj));
        emit BlackJack.Deal(false, predicted1);
        vm.expectEmit(true, true, true, true, address(bj));
        emit BlackJack.Deal(true, predicted2);
        
        vm.prank(player);
        bj.deal{value: 0.05 ether}();
    }
}
