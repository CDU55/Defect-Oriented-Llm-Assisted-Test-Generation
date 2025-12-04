
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame questGame;

    function setUp() public {
        questGame = new QuestGame{value: 0.1 ether}();
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber, address sender) public {
        
        // --- 1. Constraints ---
        vm.assume(blockTimestamp >= 1 hours);
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockNumber >= block.number);
        vm.assume(sender != address(0));
        
        // --- 2. State Configuration ---
        
        // Funding (if needed)
        vm.deal(sender, 0.1 ether);
        
        // MANIPULATE BLOCK ENVIRONMENT
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // --- 3. Replication & Assertion ---
        
        // PREDICT THE OUTCOME
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    blockTimestamp, 
                    blockNumber, 
                    sender 
                )
            )
        );

        uint256 generatedNumber = seed % 100;
                
        // EXECUTE
        vm.expectEmit(true, false, false, true, address(questGame));
        emit QuestGame.QuestAttempted(sender, false, generatedNumber);
        vm.prank(sender);
        questGame.attemptQuest{value: 0.1 ether}(100);

        // ASSERT PREDICTABILITY
        
    }
}
