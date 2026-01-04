
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {GuessTheRandomNumberChallenge} from "../src/GuessTheRandomNumberChallenge.sol";

contract TestWeakRandomnessGuessTheRandomNumberChallenge is Test {

    GuessTheRandomNumberChallenge public _contractUnderTest;

    function setUp() public {
        vm.deal(address(this), 1 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        
        vm.assume(blockTimestamp >= block.timestamp);
        
        vm.assume(blockNumber >= block.number);
        
        vm.assume(blockNumber >= 1);

        // --- 2. State Configuration ---
        
        
        // MANIPULATE BLOCK ENVIRONMENT
        
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        
        uint8 expected = uint8(uint256(keccak256(abi.encodePacked(blockhash(blockNumber - 1), blockTimestamp))));
        
        
        _contractUnderTest = new GuessTheRandomNumberChallenge{value: 1 ether}();

        
        bytes32 stored = vm.load(address(_contractUnderTest), bytes32(0));
        uint8 actual = uint8(uint256(stored));

        
        assertEq(actual, expected, "Randomness should be predictable given block state");
    }
}
