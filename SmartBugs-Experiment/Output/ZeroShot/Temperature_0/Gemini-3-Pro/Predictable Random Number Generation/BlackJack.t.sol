
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {

    BlackJack blackJack;

    function setUp() public {
        blackJack = new BlackJack();
        vm.deal(address(this), 100 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        
        // --- 1. Constraints ---
        vm.assume(blockNumber > 0);
        vm.assume(blockTimestamp > 0);
        
        // --- 2. State Configuration ---
        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        // --- 3. Replication & Assertion ---
        
        // Replicate the logic from Deck.deal to predict the cards.
        // The contract deals 3 cards in the 'deal' function:
        // 1. Player card (counter 0)
        // 2. House card (counter 1)
        // 3. Player card (counter 2)
        
        // Note: blockhash(block.number) in EVM returns 0 for the current block.
        bytes32 currentBlockhash = blockhash(block.number); 
        address player = address(this);
        
        uint8 predictedPlayerCard1 = uint8(uint256(keccak256(abi.encodePacked(currentBlockhash, player, uint8(0), block.timestamp))) % 52);
        uint8 predictedHouseCard1 = uint8(uint256(keccak256(abi.encodePacked(currentBlockhash, player, uint8(1), block.timestamp))) % 52);
        uint8 predictedPlayerCard2 = uint8(uint256(keccak256(abi.encodePacked(currentBlockhash, player, uint8(2), block.timestamp))) % 52);

        // EXECUTE
        blackJack.deal{value: 1 ether}();

        // ASSERT PREDICTABILITY
        uint8 actualPlayerCard1 = blackJack.getPlayerCard(0);
        uint8 actualHouseCard1 = blackJack.getHouseCard(0);
        uint8 actualPlayerCard2 = blackJack.getPlayerCard(1);

        assertEq(actualPlayerCard1, predictedPlayerCard1, "Player Card 1 should be predictable");
        assertEq(actualHouseCard1, predictedHouseCard1, "House Card 1 should be predictable");
        assertEq(actualPlayerCard2, predictedPlayerCard2, "Player Card 2 should be predictable");
    }

    receive() external payable {}
}
