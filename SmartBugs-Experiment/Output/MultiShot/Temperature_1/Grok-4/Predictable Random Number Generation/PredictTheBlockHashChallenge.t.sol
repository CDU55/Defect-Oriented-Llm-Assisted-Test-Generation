
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {

    PredictTheBlockHashChallenge public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 2 ether);
        _contractUnderTest = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockNumber >= block.number);
        
        
        

        // --- 2. State Configuration ---
        
        // Funding (if needed)
        

        
        

        // --- 3. Replication & Assertion ---
        
        bytes32 expectedRandom = bytes32(0);
        
        _contractUnderTest.lockInGuess{value: 1 ether}(expectedRandom);
        
        uint256 guessBlock = block.number + 1;
        
        vm.assume(blockNumber > guessBlock);
        vm.assume(blockNumber >= guessBlock + 256);
        
        vm.roll(blockNumber);
        
        bytes32 actualRandom = blockhash(guessBlock);
        
        _contractUnderTest.settle();
        
        assertEq(actualRandom, expectedRandom, "Randomness should be predictable given block state");
    }
}
