
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {
    GuessTheRandomNumberChallenge challenge;

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp, bytes32 blockHash) public {
        require(blockNumber >= 1, "blockNumber must be at least 1");
        
        vm.deal(address(this), 10 ether);
        
        vm.roll(blockNumber);
        vm.warp(blockTimestamp);
        vm.mockBlockHash(blockNumber - 1, blockHash);
        
        challenge = new GuessTheRandomNumberChallenge{value: 1 ether}();
        
        uint8 expectedAnswer = uint8(uint256(keccak256(abi.encodePacked(blockHash, blockTimestamp))));
        
        challenge.guess{value: 1 ether}(expectedAnswer);
        
        assert(challenge.isComplete());
    }
}
