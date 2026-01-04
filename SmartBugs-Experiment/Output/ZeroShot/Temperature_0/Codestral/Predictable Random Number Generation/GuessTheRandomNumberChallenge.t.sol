
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {

    GuessTheRandomNumberChallenge public challenge;

    function setUp() public {
        challenge = new GuessTheRandomNumberChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        // --- 1. Constraints ---
        blockTimestamp = blockTimestamp + 1;
        blockNumber = blockNumber + 1;

        // --- 2. State Configuration ---
        vm.deal(address(this), 1 ether);

        // --- 3. Manipulate Block Environment ---
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 4. Replication & Assertion ---
        bytes32 blockHash = blockhash(blockNumber - 1);
        uint8 expectedAnswer = uint8(uint256(keccak256(abi.encodePacked(blockHash, blockTimestamp))));

        vm.prank(address(this), 1 ether);
        challenge.guess(expectedAnswer);

        assertEq(challenge.isComplete(), true);
    }
}
