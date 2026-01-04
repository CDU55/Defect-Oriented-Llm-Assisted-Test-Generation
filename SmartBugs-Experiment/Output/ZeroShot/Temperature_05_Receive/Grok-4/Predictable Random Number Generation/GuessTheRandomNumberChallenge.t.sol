
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {

    GuessTheRandomNumberChallenge challenge;

    function setUp() public {
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber, uint256 blockTimestamp) public {
        
        // --- 1. Constraints ---
        vm.assume(blockNumber > 0);
        

        // --- 2. State Configuration ---
        
        vm.deal(address(this), 2 ether);

        vm.roll(blockNumber);
        vm.warp(blockTimestamp);

        challenge = new GuessTheRandomNumberChallenge{value: 1 ether}();

        // --- 3. Replication & Assertion ---
        
        uint8 predictedAnswer = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))));
                
        challenge.guess{value: 1 ether}(predictedAnswer);

        assertTrue(challenge.isComplete());
    }

    receive() external payable {}

    fallback() external payable {}
}
