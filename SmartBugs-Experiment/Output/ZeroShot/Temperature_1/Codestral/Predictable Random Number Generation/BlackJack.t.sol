
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {BlackJack} from "../src/BlackJack.sol";

contract TestWeakRandomnessBlackJack is Test {

    BlackJack blackJack;

    function setUp() public {
        blackJack = new BlackJack();
    }

    function test_highlightPredictableRandomValue(uint blockNumber, uint timestamp) public {
        uint256 bet = 1 ether;

        // Constraints
        blockNumber = uint(uint256(blockNumber) % 1000000);
        timestamp = uint(uint256(timestamp) % 2**32);

        // Funding
        vm.deal(address(this), bet);

        // Manipulate block environment
        vm.roll(blockNumber);
        vm.warp(timestamp);

        // Predict the outcome
        bytes32 blockHash = vm.getBlockHash(blockNumber);
        uint8 expectedCard = uint8(uint256(keccak256(abi.encodePacked(blockHash, address(this), 0, timestamp))) % 52);

        // Execute
        vm.startPrank(address(this));
        blackJack.deal{value: bet}();

        // Assert predictability
        assertEq(blackJack.getPlayerCard(0), expectedCard);
    }
}
