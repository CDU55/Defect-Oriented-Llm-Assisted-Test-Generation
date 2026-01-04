
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/LuckyDoubler.sol";

contract TestWeakRandomnessLuckyDoubler is Test {

    LuckyDoubler public contractUnderTest;

    function setUp() public {
        contractUnderTest = new LuckyDoubler();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {

        // --- 1. Constraints ---
        blockNumber = bound(blockNumber, 1, 1000000);

        // --- 2. State Configuration ---

        // Fund the contract with 2 ETH to ensure we can test the randomness
        vm.deal(address(contractUnderTest), 2 ether);

        // --- 3. Replication & Assertion ---

        // Calculate the expected random value based on the block number
        uint256 factor = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
        uint256 max = 2; // We have 2 unpaid entries (since we funded with 2 ETH)
        factor = factor * 100 / max;
        uint256 lastBlockNumber = blockNumber - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));
        uint256 expectedRandomValue = uint256((uint256(hashVal) / factor)) % max;

        // Manipulate the block number
        vm.roll(blockNumber);

        // Execute the join function which uses the random number
        vm.prank(address(1));
        vm.deal(address(1), 1 ether);
        contractUnderTest.join();

        // The second join will trigger the random selection
        vm.prank(address(2));
        vm.deal(address(2), 1 ether);
        contractUnderTest.join();

        // Verify that the random value matches our expectation
        assertEq(contractUnderTest.rand(2), expectedRandomValue);
    }
}
