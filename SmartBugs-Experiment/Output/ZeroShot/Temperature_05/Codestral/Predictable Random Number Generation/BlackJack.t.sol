
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {

    BlackJack blackJack;

    function setUp() public {
        blackJack = new BlackJack();
        deal();
    }

    function test_highlightPredictableRandomValue(uint blockNumber, uint timestamp) public {
        // --- 1. Constraints ---
        blockNumber = bound(blockNumber, 1, 1000000);
        timestamp = bound(timestamp, 1, 10000000000);

        // --- 2. State Configuration ---
        vm.deal(address(blackJack), 1 ether);

        // --- 3. Manipulate Block Environment ---
        vm.roll(blockNumber);
        vm.warp(timestamp);

        // --- 4. Replication & Assertion ---
        // Calculate expected card using the same logic as the contract
        uint8 expectedCard = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber), address(this), 0, timestamp))) % 52);

        // Execute the contract method
        blackJack.hit();

        // Assert predictability
        assertEq(blackJack.getPlayerCard(2), expectedCard);
    }
}
