
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {

    PredictTheBlockHashChallenge public contractUnderTest;

    function setUp() public {
        contractUnderTest = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        // --- 1. Constraints ---
        blockNumber = uint256(keccak256(abi.encode(blockNumber))) % 10000000000000000000000000000000000000000000000000000000000000000;

        // --- 2. State Configuration ---
        vm.deal(address(this), 1 ether);
        vm.prank(address(this));
        contractUnderTest.lockInGuess{value: 1 ether}(bytes32(0));

        // --- 3. Replication & Assertion ---
        vm.roll(blockNumber + 1);

        bytes32 expectedHash = blockhash(blockNumber + 1);

        vm.prank(address(this));
        contractUnderTest.settle();

        assertEq(contractUnderTest.guesses(address(this)).guess, expectedHash);
    }
}
