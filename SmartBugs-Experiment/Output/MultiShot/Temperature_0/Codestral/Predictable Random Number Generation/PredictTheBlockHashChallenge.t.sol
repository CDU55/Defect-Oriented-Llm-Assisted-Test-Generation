
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {

    PredictTheBlockHashChallenge public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 1 ether);
        _contractUnderTest = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber >= block.number);

        vm.deal(address(this), 1 ether);

        vm.roll(blockNumber);

        bytes32 expectedHash = blockhash(blockNumber);

        _contractUnderTest.lockInGuess{value: 1 ether}(expectedHash);

        vm.roll(blockNumber + 1);

        _contractUnderTest.settle();

        assertEq(address(_contractUnderTest).balance, 1 ether, "Contract should have paid out 2 ether");
    }
}
