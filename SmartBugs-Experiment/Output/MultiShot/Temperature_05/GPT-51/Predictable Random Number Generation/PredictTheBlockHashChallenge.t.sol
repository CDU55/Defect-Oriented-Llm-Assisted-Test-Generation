
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
        vm.assume(blockNumber < type(uint256).max - 100);

        vm.roll(blockNumber);

        bytes32 fakeGuess = bytes32(uint256(0));
        _contractUnderTest.lockInGuess{value: 1 ether}(fakeGuess);

        uint256 targetBlock = block.number + 1;
        vm.roll(targetBlock);

        bytes32 expectedAnswer = blockhash(targetBlock);

        vm.roll(targetBlock + 1);

        _contractUnderTest.settle();

        if (expectedAnswer == fakeGuess) {
            assertEq(address(this).balance, 10 ether, "Should have won 2 ether");
        } else {
            assertEq(address(this).balance, 8 ether, "Should have lost 1 ether");
        }

        assertEq(
            expectedAnswer,
            blockhash(targetBlock),
            "Randomness should be predictable from blockhash"
        );
    }
}
