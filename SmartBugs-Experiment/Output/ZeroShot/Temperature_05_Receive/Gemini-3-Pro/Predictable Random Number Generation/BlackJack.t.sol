
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {

    BlackJack blackJack;

    function setUp() public {
        blackJack = new BlackJack();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        
        // --- 1. Constraints ---
        vm.assume(blockNumber > 0);
        vm.assume(blockTimestamp > 0);

        // --- 2. State Configuration ---
        vm.deal(address(this), 10 ether);

        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        // --- 3. Replication & Assertion ---
        
        // Replicate the logic for the first card dealt to the player (cardNumber = 0)
        // The contract uses: blockhash(block.number), player (msg.sender), cardNumber, timestamp
        // Note: blockhash(block.number) evaluates to 0 in the EVM for the current block.
        
        bytes32 bHash = blockhash(block.number);
        address player = address(this);
        uint8 cardNumber = 0; // First card dealt to player in deal()
        
        uint8 expectedCard = uint8(uint256(keccak256(abi.encodePacked(bHash, player, cardNumber, blockTimestamp))) % 52);
                
        // EXECUTE
        blackJack.deal{value: 1 ether}();

        // ASSERT PREDICTABILITY
        uint8 actualCard = blackJack.getPlayerCard(0);
        assertEq(actualCard, expectedCard, "Randomness is predictable");
    }

    receive() external payable {}

    fallback() external payable {}
}
