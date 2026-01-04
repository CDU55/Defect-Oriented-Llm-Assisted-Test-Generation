
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {
    BlackJack public blackjack;

    function setUp() public {
        blackjack = new BlackJack();
        dealEthToContract();
    }

    function dealEthToContract() internal {
        vm.deal(address(blackjack), 100 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp, address player) public {
        vm.assume(blockTimestamp <= type(uint64).max);
        vm.assume(player != address(0));
        dealEthToContract();
        
        vm.roll(blockNumber);
        vm.warp(blockTimestamp);
        
        bytes32 blockHash = blockhash(blockNumber);
        uint8 cardNumber = 0;
        
        uint8 predictedCard = uint8(uint256(keccak256(abi.encodePacked(blockHash, player, cardNumber, blockTimestamp))) % 52);
        
        vm.startPrank(player);
        blackjack.deal{value: 0.05 ether}();
        
        uint8 actualCard = blackjack.getPlayerCard(0);
        
        assertEq(actualCard, predictedCard, "Predicted card should match actual card");
        vm.stopPrank();
    }
}
