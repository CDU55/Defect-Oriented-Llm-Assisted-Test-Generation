
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {RandomNumberGenerator} from "../src/RandomNumberGenerator.sol";

contract TestWeakRandomnessRandomNumberGenerator is Test {

    RandomNumberGenerator public _contractUnderTest;
    uint256 private salt;

    function setUp() public {
        salt = block.timestamp;
        _contractUnderTest = new RandomNumberGenerator();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        // Constrain blockNumber to avoid division by zero and ensure valid blockhash
        vm.assume(blockNumber >= 10);
        vm.assume(blockNumber < type(uint256).max / 2);
        
        // Ensure salt % 5 != 0 to avoid division by zero in the contract
        // salt is set at deployment time (block.timestamp), we need to ensure valid state
        uint256 currentSalt = salt;
        vm.assume(currentSalt % 5 != 0);
        
        // Ensure max is reasonable to avoid division issues
        uint256 max = 100;
        
        // Ensure seed calculation doesn't overflow
        uint256 seed = blockNumber / 3 + (currentSalt % 300) + (currentSalt * blockNumber / (currentSalt % 5));
        vm.assume(seed < blockNumber); // blockhash only works for recent 256 blocks
        vm.assume(seed > 0);

        // --- 2. State Configuration ---
        
        // Manipulate block number
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // Replicate the vulnerable logic locally
        uint256 x = currentSalt * 100 / max;
        uint256 y = currentSalt * blockNumber / (currentSalt % 5);
        uint256 expectedSeed = blockNumber / 3 + (currentSalt % 300) + y;
        uint256 h = uint256(blockhash(expectedSeed));
        uint256 expectedRandom = uint256((h / x)) % max + 1;
        
        // Execute the contract method
        uint256 actualRandom = _contractUnderTest.random(max);

        // Assert predictability - prove that the contract's "random" value matches our calculated expectation
        assertEq(actualRandom, expectedRandom, "Randomness should be predictable given block state");
    }
}
