
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {

    BlackJack public blackJack;

    function setUp() public {
        blackJack = new BlackJack();
        vm.deal(address(blackJack), 1 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockTimestamp > 0);
        vm.assume(blockNumber > 0);
        

        // --- 2. State Configuration ---
        
        address player = makeAddr("player");
        vm.deal(player, 1 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        uint8 cardNumber = 0;
        bytes32 predictedHash = keccak256(abi.encodePacked(bytes32(0), player, cardNumber, blockTimestamp));
        uint8 predictedCard = uint8(uint256(predictedHash) % 52);
                
        vm.prank(player);
        blackJack.deal{value: 0.05 ether}();

        (
            address gamePlayer,
            uint bet,
            uint8[] memory houseCards,
            uint8[] memory pCards,
            uint8 state,
            uint8 cardsDealt
        ) = blackJack.games(player);
        uint8 actualCard = pCards[0];

        assertEq(actualCard, predictedCard);
    }
}
