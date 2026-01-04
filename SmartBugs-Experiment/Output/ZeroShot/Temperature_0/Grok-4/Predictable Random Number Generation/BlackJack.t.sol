
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/src/Test.sol";
import {BlackJack} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {

    BlackJack public blackJack;

    function setUp() public {
        blackJack = new BlackJack();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        
        // --- 1. Constraints ---
        assume(blockNumber > 0);
        assume(blockTimestamp > 0);
        

        // --- 2. State Configuration ---
        
        vm.deal(address(this), 1 ether);

        
        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        // --- 3. Replication & Assertion ---
        
        address player = address(this);
        bytes32 expectedHash = bytes32(0);
        
        uint8 expectedPlayerCard0 = uint8(uint256(keccak256(abi.encodePacked(expectedHash, player, uint8(0), blockTimestamp))) % 52);
        uint8 expectedHouseCard0 = uint8(uint256(keccak256(abi.encodePacked(expectedHash, player, uint8(1), blockTimestamp))) % 52);
        uint8 expectedPlayerCard1 = uint8(uint256(keccak256(abi.encodePacked(expectedHash, player, uint8(2), blockTimestamp))) % 52);
        
        vm.expectEmit(true, true, true, true, address(blackJack));
        emit BlackJack.Deal(true, expectedPlayerCard0);
        
        vm.expectEmit(true, true, true, true, address(blackJack));
        emit BlackJack.Deal(false, expectedHouseCard0);
        
        vm.expectEmit(true, true, true, true, address(blackJack));
        emit BlackJack.Deal(true, expectedPlayerCard1);
        
        blackJack.deal{value: 0.05 ether}();
    }
}
